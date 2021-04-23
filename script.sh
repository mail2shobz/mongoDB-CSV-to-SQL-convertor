#!/bin/bash
OIFS=$IFS;
IFS=",";

# fill in your details here
printf 'Enter the DB name you want convert to CSV:'
read -r dbname
dbname=$dbname
host=127.0.0.1:27017

# first get all collections in the database
collections=`mongo "$host/$dbname" --quiet  --eval "rs.secondaryOk();db.getCollectionNames();"`;
collections=`mongo --quiet $dbname --eval "rs.secondaryOk();var names=db.getCollectionNames().join(','); names"` ;
echo $collections;

collectionArray=($collections);

# for each collection
for ((i=0; i<${#collectionArray[@]}; ++i));
do
    echo 'exporting collection' ${collectionArray[$i]}
    keys=`mongo "$host/$dbname" --eval "rs.secondaryOk();var keys = []; for(var key in db.${collectionArray[$i]}.find().sort({_id: -1}).limit(1)[0]) { keys.push(key); }; keys.join(',');" --quiet`;
    echo $keys;
    # now use mongoexport with the set of keys to export the collection to csv
    mongoexport --host $host -d $dbname -c ${collectionArray[$i]} --fields "$keys" --type=csv --out ${collectionArray[$i]}.csv --forceTableScan;
    echo "Starting Conversion ......................."
    wget https://repo1.maven.org/maven2/com/rebasedata/client/0.0.5/client-0.0.5.jar
    java -jar client-0.0.5.jar convert --output-format=postgresql ${collectionArray[$i]}.csv output-dir/
done

IFS=$OIFS;
