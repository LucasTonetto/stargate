from operator import concat
from pyspark.sql import SparkSession
from pyspark.sql.functions import col, from_json, array, arrays_zip, current_timestamp, explode, lit, concat_ws, expr
from pyspark.sql.types import *
from datetime import datetime
import os
from dotenv import load_dotenv
from google.cloud import storage

if __name__ == "__main__":
    bucket_stargate = os.environ.get("BUCKET_NAME")

    # from_service_account_json('service-account-file.json')
    storage_client = storage.Client()
    bucket = storage_client.bucket(bucket_stargate)
    blob = bucket.blob('.env')
    blob.download_to_filename('.env')
    load_dotenv()
    bigquery_dataset = os.environ.get("BIGQUERY_DATASET")
    kafka_brokers_ips = os.environ.get("BOOTSTRAP_SERVERS")
    kafka_topic_app = os.environ.get("KAFKA_TOPIC_APP")
    kafka_topic_web = os.environ.get("KAFKA_TOPIC_WEB")
    kafka_topics = f'{os.environ.get("KAFKA_TOPIC_WEB")}, {os.environ.get("KAFKA_TOPIC_APP")}'
    kafka_group = os.environ.get("KAFKA_CONSUMER_GROUP")

    checkpoint_location = f"gs://{bucket_stargate}/checkpoints/"

    print('Dataset - Bucket - Ips das Máquinas de Kafka - Tópicos do Kafka - Grupo do Spark - Checkpoint - Nome da tabela')

    print(bigquery_dataset, " - ", bucket_stargate, " - ",
          kafka_brokers_ips, " - ", kafka_topics, " - ", kafka_group, " - ", checkpoint_location)
    
    spark = SparkSession.builder \
        .appName("Spark Consumer Kafka - Stargate") \
        .config("spark.jars", "gs://spark-lib/bigquery/spark-bigquery-with-dependencies_2.12-0.24.2.jar") \
        .getOrCreate() 

    spark.sparkContext.setLogLevel("WARN")
    spark.conf.set("temporaryGcsBucket", bucket_stargate)

    df = (
        spark.readStream.format("kafka")
        .option(
            "kafka.bootstrap.servers",
            kafka_brokers_ips,
        )
        .option("subscribe", kafka_topics)
        .option("group.id", kafka_group)
        .load()
    )

    df.printSchema()
    df.selectExpr("CAST(key AS STRING) as key",
                  "CAST(value AS STRING) as value")

    df2 = df.withColumn("key", df.key.cast("string")).withColumn(
        "value", df.value.cast("string")
    )
    df2.printSchema()

    schema_bigquery = StructType([
            StructField("TipoEvento", StringType(), False),
        StructField("device", StringType(), True),
        StructField("advertiserID", StringType(), True),
        StructField("idUsuario", StringType(), True),
        StructField("appsflyerID", StringType(), True),
        StructField("clientId", StringType(), True),
        StructField("bandeira", StringType(), False),
        StructField("sistemaOperacional", StringType(), True),
        StructField("nomePagina", StringType(), True),
        StructField("idTransacao", StringType(), True),
        StructField("receita", FloatType(), True),
        StructField("skuProdutos", ArrayType(StringType()), True),
        StructField("precoProdutos", ArrayType(StringType()), True),
        StructField("qtdProdutos", ArrayType(StringType()), True),
        StructField("produtos", StructType([
            StructField("quantity", IntegerType(), True),
            StructField("id", StringType(), True),
            StructField("name", StringType(), True),
            StructField("brand", StringType(), True),
            StructField("price", FloatType(), True)
        ])),
        StructField("valorFrete", FloatType(), True),
        StructField("serverTime", DateType(), True),
        StructField("eventCategory", StringType(), True),
        StructField("eventAction", StringType(), True),
        StructField("eventLabel", StringType(), True),
        StructField("referrer", StringType(), True),
        StructField("utmSource", StringType(), True),
        StructField("utmMedium", StringType(), True),
        StructField("utmCampaign", StringType(), True),
        StructField("hitTime", DateType(), True)
        ])

    dataframe = df2.withColumn("dataLayer", from_json(col("value"), schema_bigquery)).select(col('dataLayer.*'))
    dataframe = dataframe.drop(col("serverTime")).withColumn("serverTime", current_timestamp())
    dataframe.printSchema()

    # Quebrando os arrays enviados dos campos qtdProdutos, skuProdutos e precoProdutos em uma linha diferente no objeto produtos (quantity, id, price)
    dataframe_app = dataframe \
    .drop(col("produtos")) \
    .withColumn("tmp", 
        arrays_zip(
            col("qtdProdutos").alias("quantity"),
            col("skuProdutos").alias("id"),
            col("precoProdutos").alias("price")
            )
    ).withColumn("produtos", 
        explode("tmp")) \
    .filter(
        (col("device") == "app") 
        &
        ((col("skuProdutos").isNotNull()) & (col("skuProdutos") != array(lit("")))
        )) \
    .drop(col("tmp")) \
    .select("*")

    # Juntando o dataframe original com o de app transformado
    dataframe = dataframe.unionByName(dataframe_app, allowMissingColumns=True)

    dataframe = dataframe \
        .withColumn("qtdProdutos", concat_ws(",", "qtdProdutos")) \
        .withColumn("skuProdutos", concat_ws(",", "skuProdutos")) \
        .withColumn("precoProdutos", concat_ws(",", "precoProdutos")) \
        .withColumn("produtos", col("produtos").withField("price", col("produtos.precoProdutos"))) \
        .withColumn("produtos", col("produtos").withField("quantity", col("produtos.qtdProdutos"))) \
        .withColumn("produtos", col("produtos").withField("id", col("produtos.skuProdutos"))) \
        .withColumn("produtos", col("produtos").dropFields("precoProdutos", "skuProdutos", "qtdProdutos")) 

    dataframe.printSchema()

    # Criando um novo datagrame final (a forma do Spark remover linhas, pois um dataframe é imutável)
    # Primeiro filtro, onde o campo skuProdutos é diferente de um array vazio ou não é nulo, e produtos ta populado (eventos de app que têm produtos e os dados de app transformados)
    # Segundo filtro, é onde um skuProdutos é vazio (eventos de pageview, screenview, etc)
    # Terceiro filtro web, pois não há nenhuma transformação a ser feita
    dataframe = dataframe.filter(
        (
            ((col("skuProdutos") != "") | (col("skuProdutos").isNotNull())) & (col("produtos").isNotNull())
        ) 
        |
        (
            ((col("skuProdutos") == "") | col("skuProdutos").isNull())
        )
        |
        (
            col("device") == "web"
        )
    )

    def filter_each_sink(dataframe, epoch_id):
        dataframe.persist()

        dataframe.show(truncate=False)
        today_date = spark.sql("select date_format(current_timestamp(),'yyyyMMdd') as today_date").collect()[0].__getitem__('today_date')

        dataframe \
        .filter((col("device") == "app") & (col("bandeira") == "drogasil")) \
        .write \
        .format('bigquery') \
        .mode('append') \
        .option('table', f"{bigquery_dataset}.drogasil_app_teste_{today_date}") \
        .save()

        dataframe \
        .filter((col("device") == "web") & (col("bandeira") == "drogasil")) \
        .write \
        .format('bigquery') \
        .mode('append') \
        .option('table', f"{bigquery_dataset}.drogasil_web_teste_{today_date}") \
        .save()   

        dataframe \
        .filter((col("device") == "app") & (col("bandeira") == "drogaraia")) \
        .write \
        .format('bigquery') \
        .mode('append') \
        .option('table', f"{bigquery_dataset}.drogaraia_app_teste_{today_date}") \
        .save()   

        dataframe \
        .filter((col("device") == "web") & (col("bandeira") == "drogaraia")) \
        .write \
        .format('bigquery') \
        .mode('append') \
        .option('table', f"{bigquery_dataset}.drogaraia_web_teste_{today_date}") \
        .save()

        dataframe.unpersist()           
  
    query = dataframe \
    .writeStream \
    .foreachBatch(filter_each_sink) \
    .outputMode("append") \
    .option("checkpointLocation", checkpoint_location) \
    .trigger(processingTime="60 second") \
    .start() \
    .awaitTermination()  
    