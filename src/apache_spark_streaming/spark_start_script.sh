echo "Informando ao projeto o nome do bucket onde ficarão armazenadas todas as informações da estrutura"

STARGATE_BUCKET_NAME=$(/usr/share/google/get_metadata_value attributes/dataproc-bucket)
echo "export STARGATE_BUCKET_NAME=${STARGATE_BUCKET_NAME}" | tee -a /etc/profile.d/spark_config.sh /etc/*bashrc /usr/lib/spark/conf/spark-env.sh tee $HOME/.bashrc

source $HOME/.bashrc

echo "Instalando Dependencias"
pip install python-dotenv
pip install google-cloud-storage