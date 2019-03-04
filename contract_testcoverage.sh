echo "Process initiated"

cd $(pwd)/contracts
chmod +777 *
for file in *; do 
    if [ -f "$file" ]; then 
        echo "$file" 
        sed -i 's/\^//g' $file
        sed -i 's/0.5.1/0.4.24/g' $file
    fi 
done
cd ..

# node setup
# Cleaning up the docker setup
docker volume prune -f || true

docker network create -d bridge --subnet 172.16.239.0/24 --gateway 172.16.239.1 app_net || true
docker network create -d bridge --subnet 172.19.240.0/24 --gateway 172.19.240.1 test_net || true

docker-compose down || true

docker-compose up -d || true

sed -i 's/version": "1.0/version": "1.0.0/g' package.json

npm install || true

# replacing validator node ip in setup.js

nodename=$(docker ps -a| grep validator-0_1 | awk '{print $1}')
ipaddr=$(docker inspect --format "{{ .NetworkSettings.Networks.test_net.IPAddress }}" $nodename)

npm install --only=dev || true
npm install bignumber.js --save || true

echo "npm test"
sed -i 's/localhost/'"$ipaddr"'/g' setup.js
sed -i 's/mocha protocol http/mocha --reporter=xunit/g' package.json
sed -i 's/\.\/test/\.\/test>api-test-reports\.xml/g' package.json

# Running tests
npm test ||true

sed -i '/Mocha Tests/,$!d' api-test-reports.xml
sed -i '/\/testsuite/,$d' api-test-reports.xml

# echo '</testsuite>' >> api-test-reports.xml
echo &apos;&lt;/testsuite&gt;&apos; &gt;&gt; api-test-reports.xml
cp apt-test-reports.xml logs.txt
echo "Process completed"
