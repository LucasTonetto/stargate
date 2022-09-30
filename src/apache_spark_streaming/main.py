from importlib.resources import path
from pyspark.sql import SparkSession
from pyspark.sql.functions import col, from_json
from pyspark.sql.types import *
import os
from dotenv import load_dotenv
from google.cloud import storage

bucket_stargate = os.environ.get("BUCKET_NAME")

storage_client = storage.Client() #from_service_account_json('service-account-file.json') 
bucket = storage_client.bucket(bucket_stargate)
blob = bucket.blob('.env')
blob.download_to_filename('.env')

load_dotenv()
bigquery_dataset = os.environ.get("BIGQUERY_DATASET")
kafka_brokers_ips = os.environ.get("BOOTSTRAP_SERVERS")
kafka_topic = os.environ.get("KAFKA_TOPIC_NAME")
kafka_group = os.environ.get("KAFKA_CONSUMER_GROUP")

print('AQUI-----------------------')
print(bigquery_dataset, bucket_stargate, kafka_brokers_ips, kafka_topic, kafka_group)

spark = SparkSession.builder.appName("Spark Consumer Kafka - Stargate").getOrCreate()
spark.sparkContext.setLogLevel("WARN")

spark.conf.set("temporaryGcsBucket", bucket_stargate)

df = (
    spark.readStream.format("kafka")
    .option(
        "kafka.bootstrap.servers",
        kafka_brokers_ips,
    )
    .option("subscribe", kafka_topic)
    .option("group.id", kafka_group)
    .load()
)

df.printSchema()
df.selectExpr("CAST(key AS STRING) as key", "CAST(value AS STRING) as value")

df2 = df.withColumn("key", df.key.cast("string")).withColumn(
    "value", df.value.cast("string")
)
df2.printSchema()

schema_bigquery = StructType([
    StructField("hitType", StringType(), True),
    StructField("page", StringType(), True),    
    StructField("clientId", StringType(), True),
    StructField("eventCategory", StringType(), True),
    StructField("eventAction", StringType(), True),
    StructField("eventLabel", StringType(), True),
    StructField("utmSource", StringType(), True),
    StructField("utmMedium", StringType(), True),
    StructField("utmCampaign", StringType(), True),
    StructField("timestampGTM", StringType(), True),
])

dataframe = df2.withColumn("dataLayer", from_json(col("value"), schema_bigquery)).select(col('dataLayer.*'), col('key'), col("topic"), col('partition'), col('offset'), col('timestamp'))

query = (
    dataframe.writeStream.format("console").outputMode("append")
    .trigger(processingTime="60 second")
    .start()
)

query = (
    dataframe.writeStream 
    .format("bigquery") 
    .option("checkpointLocation", f"gs://{bucket_stargate}/checkpoints/") 
    .option("table", kafka_topic)
    .trigger(processingTime="60 second")
    .start()
)

query.awaitTermination()