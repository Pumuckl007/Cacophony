export CFLAGS=-fPIC
lastBuild=`cat lastbuildarchetecture.txt`
if [ "$lastBuild" = "amd64" ]
then
	make || echo "Done."
else
	make clean
	./configure --host arm-linux-gnueabihf
	make || echo "Done."
fi
rm lastbuildarchetecture.txt
echo "amd64" >> lastbuildarchetecture.txt
