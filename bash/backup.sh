#!/bin/sh

BACKUP_DIR=/path/to/backup_dir
CONF_FILE='config.txt'

Dump() {
    DATE=`date '+%m.%d.%y_%H:%M'`
    /usr/bin/mongodump --host $1 --port $2 -d $3 --gzip --archive=$BACKUP_DIR/$3/days/$3.$DATE.gz
    rm $BACKUP_DIR/$3/days/last.gz
    ln -s $BACKUP_DIR/$3/days/$3.$DATE.gz $BACKUP_DIR/$3/days/last.gz

}

for i in `cat $CONF_FILE`; do
    echo "Dumping $3"
    IP=`echo $i | awk -F ":" '{print $1}'`
    PORT=`echo $i | awk -F ":" '{print $2}'`
    DB=`echo $i | awk -F ":" '{print $3}'`
    mkdir -p $BACKUP_DIR/$DB/days
    mkdir -p $BACKUP_DIR/$DB/month
    mkdir -p $BACKUP_DIR/$DB/h_year
    Dump $IP $PORT $DB
    file=`find $BACKUP_DIR/$DB/month/ -type f -mtime -30`
    if [ "$file" = "" ]; then
        cp $BACKUP_DIR/$DB/days/$DB.$DATE.gz  $BACKUP_DIR/$DB/month/
    fi
    file=`find $BACKUP_DIR/$DB/h_year/ -type f -mtime -180`
    if [ "$file" = "" ]; then
        cp $BACKUP_DIR/$DB/days/$DB.$DATE.gz $BACKUP_DIR/$DB/h_year/
    fi
    find $BACKUP_DIR/$DB/days/ -type f -mtime +3 -exec rm {} \;
done
