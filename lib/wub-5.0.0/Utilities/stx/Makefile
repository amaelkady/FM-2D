backup: clean docs
	(cd ..; tar czv --exclude='stx/backup/*' -f stx-`date +%F`.tar.gz stx)
	cp ../stx-`date +%F`.tar.gz ./stx.tar.gz

export:
	-scp -p ../stx-`date +%F`.tar.gz roselea.dyndns.org:public_html/stx/stx.tar.gz
	-scp -p index.html stx.stx stx.css logo125.gif roselea.dyndns.org:public_html/stx/

docs:
	./stx2html < stx.stx > index.html

clean:
	-rm index.html
	-rm -r *.o *~ */*~
	-rm stx.tar.gz
