export CC=arm-linux-gnueabihf-gcc
export CFLAGS=-fPIC
lastBuild=`cat lastbuildarchetecture.txt`
if [ "$lastBuild" = "arm" ]
then
	make || echo "Done."
else
	make clean
	./configure --host arm-linux-gnueabihf
	make || echo "Done."
fi
rm lastbuildarchetecture.txt
echo "arm" >> lastbuildarchetecture.txt
