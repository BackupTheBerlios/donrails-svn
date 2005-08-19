#!/usr/bin/make

all: link

link: linkrails linkinit links linkj 
copy: copyrails copyinit

linkrails:
	rails rails

copyrails:
	rails -C rails

linkinit:
	cd rails; rm -rf app; ln -s ../donrails/app .
	cd rails/config; rm routes.rb; ln -s ../../donrails/config/routes.rb .

links:
	cd rails/public/stylesheets ; ln -s ../../../donrails/public/stylesheets/*.css .
linkj:
	cd rails/public/javascripts ; ln -s ../../../donrails/public/javascripts/*.js .

copyinit:
	cd rails; rm -rf app; cp -r ../donrails/app .
	cd rails/config; rm routes.rb; cp ../../donrails/config/routes.rb .

imagedumpdir:
	mkdir rails/public/images/dump && chmod a+w rails/public/images/dump

dbdir:
	chmod a+w rails/db


dist: clean
	cd .. ; tar --exclude .svn --exclude rails --exclude donrails/app/views/notes/index.rhtml --exclude donrails/app/views/layouts/notes.rhtml -zcvf donrails-`cat donrails/VERSION`_`date +%Y%m%d`.tar.gz donrails/

clean:
	rm -f *~ */*~ */*/*~ */*/*/*~ */*/*/*/*~ *.orig */*.orig */*/*.orig
