package provide mime-magic 1.0
package require magiclib

namespace eval ::magic {}

proc ::magic::/magic.mime {} {
    switch -- [Nv I 0 ] 779248125 {emit audio/x-pn-realaudio} 442 {emit video/mpeg} 443 {emit video/mpeg} 432 {emit video/mp4v-es} 437 {emit video/mp4v-es} 435 {emit video/mpv} 324508366 {emit application/x-gdbm} 398689 {emit application/x-dbm} 235082497 {emit {Hierarchical Data Format \(version 4\) data}} 6656 {emit application/x-123} 512 {emit application/x-123} 834535424 {emit application/msword} 
    if {[S 0 == .RMF ]} {emit application/vnd.rn-realmedia}
    if {[S 0 == MAS_UTrack_V00 ]} {
	if {[S 14 > /0 ]} {emit audio/x-mod}
    }
    if {[S 0 == {Extended\ Module:} ]} {emit audio/x-mod}
    if {[S 21 == !SCREAM! c]} {emit audio/x-mod}
    if {[S 21 == BMOD2STM ]} {emit audio/x-mod}
    if {[S 1080 == M.K. ]} {emit audio/x-mod}
    if {[S 1080 == M!K! ]} {emit audio/x-mod}
    if {[S 1080 == FLT4 ]} {emit audio/x-mod}
    if {[S 1080 == FLT8 ]} {emit audio/x-mod}
    if {[S 1080 == 4CHN ]} {emit audio/x-mod}
    if {[S 1080 == 6CHN ]} {emit audio/x-mod}
    if {[S 1080 == 8CHN ]} {emit audio/x-mod}
    if {[S 1080 == CD81 ]} {emit audio/x-mod}
    if {[S 1080 == OKTA ]} {emit audio/x-mod}
    if {[S 1080 == 16CN ]} {emit audio/x-mod}
    if {[S 1080 == 32CN ]} {emit audio/x-mod}
    if {[S 0 == IMPM ]} {emit audio/x-mod}
    if {[S 0 == <?xml ]} {
	if {[S 38 == {<\!DOCTYPE\040svg} ]} {emit image/svg+xml}
    }
    if {[S 0 == <?xml ]} {emit text/xml}
    switch -- [Nv S 0 ] -13570 {emit {}
	if {[N S 2 == 0xbabe ]} {emit application/java}
    } 7967 {emit application/octet-stream} 8191 {emit application/octet-stream} -13563 {emit application/octet-stream} 29127 {emit application/x-cpio} -14479 {emit {application/x-cpio	swapped}} -4693 {emit {}
	if {[N S 2 == 0xeedb ]} {emit application/x-rpm}
    } -40 {emit image/jpeg} -26368 {emit {text/PGP key public ring}} -27391 {emit {text/PGP key security ring}} -27392 {emit {text/PGP key security ring}} -23040 {emit {text/PGP encrypted data}} -31487 {emit data} -26367 {emit {text/GnuPG key public ring}} -31487 {emit {text/OpenPGP data}} 
    if {[S 0 == .snd ]} {switch -- [Nv I 12 ] 1 {emit audio/basic} 2 {emit audio/basic} 3 {emit audio/basic} 4 {emit audio/basic} 5 {emit audio/basic} 6 {emit audio/basic} 7 {emit audio/basic} 23 {emit audio/x-adpcm} 
    }
    switch -- [Nv i 0 ] 6583086 {emit {}
	switch -- [Nv i 12 ] 1 {emit audio/x-dec-basic} 2 {emit audio/x-dec-basic} 3 {emit audio/x-dec-basic} 4 {emit audio/x-dec-basic} 5 {emit audio/x-dec-basic} 6 {emit audio/x-dec-basic} 7 {emit audio/x-dec-basic} 23 {emit audio/x-dec-adpcm} 
    } 324508366 {emit application/x-gdbm} 574529400 {emit application/ms-tnef} 
    if {[S 8 == AIFF ]} {emit {audio/x-aiff	}}
    if {[S 8 == AIFC ]} {emit {audio/x-aiff	}}
    if {[S 8 == 8SVX ]} {emit {audio/x-aiff	}}
    if {[S 0 == MThd ]} {emit {audio/unknown	}}
    if {[S 0 == CTMF ]} {emit {audio/unknown	}}
    if {[S 0 == SBI ]} {emit {audio/unknown	}}
    if {[S 0 == {Creative\ Voice\ File} ]} {emit {audio/unknown	}}
    if {[S 0 == RIFF ]} {
	if {[S 8 == WAVE ]} {emit audio/x-wav}
	if {[S 8 == AVI B]} {emit video/x-msvideo}
	if {[S 8 == CDRA ]} {emit image/x-coreldraw}
    }
    if {[N S 0 == 0xfffa &0xfffe]} {emit audio/mpeg}
    if {[S 0 == ID3 ]} {emit audio/mpeg}
    if {[S 0 == OggS ]} {emit application/ogg}
    if {[S 0 == {/*\ XPM} ]} {emit {image/x-xpm	7bit}}
    if {[S 0 == {\#!/bin/sh} ]} {emit application/x-shellscript}
    if {[S 0 == {\#!\ /bin/sh} ]} {emit application/x-shellscript}
    if {[S 0 == {\#!/bin/csh} ]} {emit application/x-shellscript}
    if {[S 0 == {\#!\ /bin/csh} ]} {emit application/x-shellscript}
    if {[S 0 == {\#!/bin/ksh} ]} {emit application/x-shellscript}
    if {[S 0 == {\#!\ /bin/ksh} ]} {emit application/x-shellscript}
    if {[S 0 == {\#!/bin/tcsh} ]} {emit application/x-shellscript}
    if {[S 0 == {\#!\ /bin/tcsh} ]} {emit application/x-shellscript}
    if {[S 0 == {\#!/usr/local/tcsh} ]} {emit application/x-shellscript}
    if {[S 0 == {\#!\ /usr/local/tcsh} ]} {emit application/x-shellscript}
    if {[S 0 == {\#!/usr/local/bin/tcsh} ]} {emit application/x-shellscript}
    if {[S 0 == {\#!\ /usr/local/bin/tcsh} ]} {emit application/x-shellscript}
    if {[S 0 == {\#!/bin/bash} ]} {emit application/x-shellscript}
    if {[S 0 == {\#!\ /bin/bash} ]} {emit application/x-shellscript}
    if {[S 0 == {\#!/usr/local/bin/bash} ]} {emit application/x-shellscript}
    if {[S 0 == {\#!\ /usr/local/bin/bash} ]} {emit application/x-shellscript}
    if {[S 0 == {\#!/bin/zsh} ]} {emit application/x-shellscript}
    if {[S 0 == {\#!/usr/bin/zsh} ]} {emit application/x-shellscript}
    if {[S 0 == {\#!/usr/local/bin/zsh} ]} {emit application/x-shellscript}
    if {[S 0 == {\#!\ /usr/local/bin/zsh} ]} {emit application/x-shellscript}
    if {[S 0 == {\#!/usr/local/bin/ash} ]} {emit application/x-shellscript}
    if {[S 0 == {\#!\ /usr/local/bin/ash} ]} {emit application/x-shellscript}
    if {[S 0 == {\#!/bin/nawk} ]} {emit application/x-nawk}
    if {[S 0 == {\#!\ /bin/nawk} ]} {emit application/x-nawk}
    if {[S 0 == {\#!/usr/bin/nawk} ]} {emit application/x-nawk}
    if {[S 0 == {\#!\ /usr/bin/nawk} ]} {emit application/x-nawk}
    if {[S 0 == {\#!/usr/local/bin/nawk} ]} {emit application/x-nawk}
    if {[S 0 == {\#!\ /usr/local/bin/nawk} ]} {emit application/x-nawk}
    if {[S 0 == {\#!/bin/gawk} ]} {emit application/x-gawk}
    if {[S 0 == {\#!\ /bin/gawk} ]} {emit application/x-gawk}
    if {[S 0 == {\#!/usr/bin/gawk} ]} {emit application/x-gawk}
    if {[S 0 == {\#!\ /usr/bin/gawk} ]} {emit application/x-gawk}
    if {[S 0 == {\#!/usr/local/bin/gawk} ]} {emit application/x-gawk}
    if {[S 0 == {\#!\ /usr/local/bin/gawk} ]} {emit application/x-gawk}
    if {[S 0 == {\#!/bin/awk} ]} {emit application/x-awk}
    if {[S 0 == {\#!\ /bin/awk} ]} {emit application/x-awk}
    if {[S 0 == {\#!/usr/bin/awk} ]} {emit application/x-awk}
    if {[S 0 == {\#!\ /usr/bin/awk} ]} {emit application/x-awk}
    if {[S 0 == BEGIN ]} {emit application/x-awk}
    if {[S 0 == {\#!/bin/perl} ]} {emit application/x-perl}
    if {[S 0 == {\#!\ /bin/perl} ]} {emit application/x-perl}
    if {[S 0 == {eval\ \"exec\ /bin/perl} ]} {emit application/x-perl}
    if {[S 0 == {\#!/usr/bin/perl} ]} {emit application/x-perl}
    if {[S 0 == {\#!\ /usr/bin/perl} ]} {emit application/x-perl}
    if {[S 0 == {eval\ \"exec\ /usr/bin/perl} ]} {emit application/x-perl}
    if {[S 0 == {\#!/usr/local/bin/perl} ]} {emit application/x-perl}
    if {[S 0 == {\#!\ /usr/local/bin/perl} ]} {emit application/x-perl}
    if {[S 0 == {eval\ \"exec\ /usr/local/bin/perl} ]} {emit application/x-perl}
    if {[S 0 == {PK\003\004} ]} {emit application/x-zip}
    if {[S 0 == Rar! ]} {emit application/x-rar}
    if {[S 0 == {\037\036} ]} {emit application/octet-stream}
    if {[S 0 == {\377\037} ]} {emit application/octet-stream}
    if {[S 257 == {ustar\0} ]} {emit {application/x-tar	posix}}
    if {[S 257 == {ustar\040\040\0} ]} {emit {application/x-tar	gnu}}
    if {[S 0 == <ar> ]} {emit application/x-archive}
    if {[S 0 == !<arch> ]} {emit application/x-archive
	if {[S 8 == debian ]} {emit application/x-debian-package}
    }
    switch -- [Nv i 0 &0x8080ffff] 2074 {emit {application/x-arc	lzw}} 2330 {emit {application/x-arc	squashed}} 538 {emit {application/x-arc	uncompressed}} 794 {emit {application/x-arc	packed}} 1050 {emit {application/x-arc	squeezed}} 1562 {emit {application/x-arc	crunched}} 2074 {emit application/x-arc} 2330 {emit application/x-arc} 538 {emit application/x-arc} 794 {emit application/x-arc} 1050 {emit application/x-arc} 1562 {emit application/x-arc} 
    switch -- [Nv s 0 ] -5536 {emit application/x-arj} 759 {emit application/x-dvi} -20719 {emit video/fli} -20718 {emit video/flc} 
    if {[S 2 == -lh0- ]} {emit {application/x-lharc	lh0}}
    if {[S 2 == -lh1- ]} {emit {application/x-lharc	lh1}}
    if {[S 2 == -lz4- ]} {emit {application/x-lharc	lz4}}
    if {[S 2 == -lz5- ]} {emit {application/x-lharc	lz5}}
    if {[S 2 == -lzs- ]} {emit {application/x-lha	lzs}}
    if {[S 2 == {-lh\ -} ]} {emit {application/x-lha	lh}}
    if {[S 2 == -lhd- ]} {emit {application/x-lha	lhd}}
    if {[S 2 == -lh2- ]} {emit {application/x-lha	lh2}}
    if {[S 2 == -lh3- ]} {emit {application/x-lha	lh3}}
    if {[S 2 == -lh4- ]} {emit {application/x-lha	lh4}}
    if {[S 2 == -lh5- ]} {emit {application/x-lha	lh5}}
    if {[S 2 == -lh6- ]} {emit {application/x-lha	lh6}}
    if {[S 2 == -lh7- ]} {emit {application/x-lha	lh7}}
    if {[S 10 == {\#\ This\ is\ a\ shell\ archive} ]} {emit {application/octet-stream	x-shell}}
    if {[S 0 == <MakerFile ]} {emit application/x-frame}
    if {[S 0 == <MIFFile ]} {emit application/x-frame}
    if {[S 0 == <MakerDictionary ]} {emit application/x-frame}
    if {[S 0 == <MakerScreenFon ]} {emit application/x-frame}
    if {[S 0 == <MML ]} {emit application/x-frame}
    if {[S 0 == <Book ]} {emit application/x-frame}
    if {[S 0 == <Maker ]} {emit application/x-frame}
    if {[S 0 == {<!DOCTYPE\ html} cB]} {emit text/html}
    if {[S 0 == <head cb]} {emit text/html}
    if {[S 0 == <title cb]} {emit text/html}
    if {[S 0 == <html bc]} {emit text/html}
    if {[S 0 == <!-- ]} {emit text/html}
    if {[S 0 == <h1 c]} {emit text/html}
    if {[S 0 == <?xml ]} {emit text/xml}
    if {[S 0 == P1 ]} {emit {image/x-portable-bitmap	7bit}}
    if {[S 0 == P2 ]} {emit {image/x-portable-greymap	7bit}}
    if {[S 0 == P3 ]} {emit {image/x-portable-pixmap	7bit}}
    if {[S 0 == P4 ]} {emit image/x-portable-bitmap}
    if {[S 0 == P5 ]} {emit image/x-portable-greymap}
    if {[S 0 == P6 ]} {emit image/x-portable-pixmap}
    if {[S 0 == IIN1 ]} {emit image/x-niff}
    if {[S 0 == MM ]} {emit image/tiff}
    if {[S 0 == II ]} {emit image/tiff}
    if {[S 0 == GIF94z ]} {emit image/unknown}
    if {[S 0 == FGF95a ]} {emit image/unknown}
    if {[S 0 == PBF ]} {emit image/unknown}
    if {[S 0 == GIF ]} {emit image/gif}
    if {[S 0 == BM ]} {emit image/x-ms-bmp}
    if {[S 32769 == CD001 ]} {emit application/x-iso9660}
    if {[S 0 == StuffIt ]} {emit application/x-stuffit}
    if {[S 11 == {must\ be\ converted\ with\ BinHex\ 4} ]} {emit application/mac-binhex40}
    if {[S 0 == {;;} ]} {emit {text/plain	8bit}}
    if {[S 0 == {\012\(}]} {emit application/x-elc}
    if {[S 0 == {;ELC\023\000\000\000} ]} {emit application/x-elc}
    if {[S 0 == Relay-Version: ]} {emit {message/rfc822	7bit}}
    if {[S 0 == {\#!\ rnews} ]} {emit {message/rfc822	7bit}}
    if {[S 0 == {N\#!\ rnews} ]} {emit {message/rfc822	7bit}}
    if {[S 0 == {Forward\ to} ]} {emit {message/rfc822	7bit}}
    if {[S 0 == {Pipe\ to} ]} {emit {message/rfc822	7bit}}
    if {[S 0 == Return-Path: ]} {emit {message/rfc822	7bit}}
    if {[S 0 == Received: ]} {emit message/rfc822}
    if {[S 0 == Path: ]} {emit {message/news	8bit}}
    if {[S 0 == Xref: ]} {emit {message/news	8bit}}
    if {[S 0 == From: ]} {emit {message/rfc822	7bit}}
    if {[S 0 == Article ]} {emit {message/news	8bit}}
    if {[S 0 == {\376\067\0\043} ]} {emit application/msword}
    if {[S 0 == {\320\317\021\340\241\261} ]} {emit application/msword}
    if {[S 0 == {\333\245-\0\0\0} ]} {emit application/msword}
    if {[S 0 == %! ]} {emit application/postscript}
    if {[S 0 == {\004%!} ]} {emit application/postscript}
    if {[S 0 == %PDF- ]} {emit application/pdf}
    if {[S 38 == Spreadsheet ]} {emit application/x-sc}
    if {[S 0 == {\367\002} ]} {emit application/x-dvi}
    if {[S 2 == {\000\021} ]} {emit application/x-tex-tfm}
    if {[S 2 == {\000\022} ]} {emit application/x-tex-tfm}
    if {[S 0 == {\\input\ texinfo} ]} {emit text/x-texinfo}
    if {[S 0 == {This\ is\ Info\ file} ]} {emit text/x-info}
    if {[S 0 == {\{\\rtf} ]} {emit text/rtf}
    if {[N I 0 == 0x47400010 &0xFF5FFF1F]} {emit video/mp2t}
    if {[S 0 == MOVI ]} {emit video/sgi}
    if {[S 4 == moov ]} {emit video/quicktime}
    if {[S 4 == mdat ]} {emit video/quicktime}
    if {[S 4 == wide ]} {emit video/quicktime}
    if {[S 4 == skip ]} {emit video/quicktime}
    if {[S 4 == free ]} {emit video/quicktime}
    if {[S 4 == idsc ]} {emit image/x-quicktime}
    if {[S 4 == idat ]} {emit image/x-quicktime}
    if {[S 4 == pckg ]} {emit application/x-quicktime}
    if {[S 4 == jP B]} {emit image/jp2}
    if {[S 4 == ftyp ]} {emit application/octet-stream
	if {[S 8 == isom ]} {emit video/mp4}
	if {[S 8 == mp41 ]} {emit video/mp4}
	if {[S 8 == mp42 ]} {emit video/mp4}
	if {[S 8 == jp2 B]} {emit image/jp2}
	if {[S 8 == 3gp ]} {emit video/3gpp}
	if {[S 8 == mmp4 ]} {emit video/mp4}
	if {[S 8 == M4A B]} {emit audio/mp4}
	if {[S 8 == qt B]} {emit video/quicktime}
    }
    switch -- [Nv c 0 ] 1 {emit video/unknown} 2 {emit video/unknown} 
    if {[S 0 == GDBM ]} {emit application/x-gdbm}
    if {[S 0 == {\177ELF} ]} {switch -- [Nv s 16 ] 0 {emit application/octet-stream} 1 {emit application/x-object} 2 {emit application/x-executable} 3 {emit application/x-sharedlib} 4 {emit application/x-coredump} 
	switch -- [Nv S 16 ] 0 {emit application/octet-stream} 1 {emit application/x-object} 2 {emit application/x-executable} 3 {emit application/x-sharedlib} 4 {emit application/x-coredump} 
    }
    if {[S 0 == MZ ]} {emit application/x-dosexec}
    if {[S 0 == {[KDE\ Desktop\ Entry]} ]} {emit application/x-kdelnk}
    if {[S 0 == {\\#\ KDE\ Config\ File} ]} {emit application/x-kdelnk}
    if {[S 0 == {\\#\ xmcd} ]} {emit text/xmcd}
    if {[S 0 == {\#\ PaCkAgE\ DaTaStReAm} ]} {emit application/x-svr4-package}
    if {[S 0 == {\x89PNG} ]} {emit image/png}
    if {[S 0 == {\x8aMNG} ]} {emit video/x-mng}
    if {[S 0 == {\x8aJNG} ]} {emit video/x-jng}
    if {[S 0 == {\211HDF\r\n\032} ]} {emit {Hierarchical Data Format \(version 5\) data}}
    if {[S 0 == 8BPS ]} {emit image/x-photoshop}
    if {[S 0 == d8:announce ]} {emit application/x-bittorrent}
    if {[S 4 == {Standard\ Jet\ DB} ]} {emit application/msaccess}
    if {[S 0 == {-----BEGIN\040PGP} ]} {emit {text/PGP armored data}
	if {[S 15 == {PUBLIC\040KEY\040BLOCK-} ]} {emit {public key block}}
	if {[S 15 == MESSAGE- ]} {emit message}
	if {[S 15 == {SIGNED\040MESSAGE-} ]} {emit {signed message}}
	if {[S 15 == {PGP\040SIGNATURE-} ]} {emit signature}
    }
    if {[S 0 == FWS ]} {
	if {[N c 3 x {} ]} {emit application/x-shockwave-flash}
    }
    if {[S 0 == BZh ]} {emit application/x-bzip2}
    if {[S 0 == {\#VRML\ V1.0\ ascii} ]} {emit model/vrml}
    if {[S 0 == {\#VRML\ V2.0\ utf8} ]} {emit model/vrml}
    if {[S 0 == DOC ]} {
	if {[N c 43 == 0x14 ]} {emit application/ichitaro4}
	if {[S 144 == JDASH ]} {emit application/ichitaro4}
    }
    if {[S 0 == DOC ]} {
	if {[N c 43 == 0x15 ]} {emit application/ichitaro5}
    }
    if {[S 0 == DOC ]} {
	if {[N c 43 == 0x16 ]} {emit application/ichitaro6}
    }
    if {[S 2080 == {Microsoft\ Excel\ 5.0\ Worksheet} ]} {emit application/excel}
    if {[S 2114 == Biff5 ]} {emit application/excel}
    if {[S 0 == {\224\246\056} ]} {emit application/msword}
    if {[S 0 == PO^Q` ]} {emit application/msword}
    if {[S 0 == {\320\317\021\340\241\261\032\341} ]} {
	if {[S 546 == bjbj ]} {emit application/msword}
	if {[S 546 == jbjb ]} {emit application/msword}
    }
    if {[S 512 == {R\0o\0o\0t\0\ \0E\0n\0t\0r\0y} ]} {emit application/msword}
    if {[S 2080 == {Microsoft\ Word\ 6.0\ Document} ]} {emit application/msword}
    if {[S 2080 == {Documento\ Microsoft\ Word\ 6} ]} {emit application/msword}
    if {[S 2112 == MSWordDoc ]} {emit application/msword}
    if {[S 0 == {\320\317\021\340\241\261\032\341} ]} {emit application/msword}
    if {[S 0 == {\#\ PaCkAgE\ DaTaStReAm} ]} {emit application/x-svr4-package}
    if {[S 128 == {PE\000\000} ]} {emit application/octet-stream}
    if {[S 0 == {PE\000\000} ]} {emit application/octet-stream}
    if {[S 0 == LZ ]} {emit application/octet-stream}
    if {[S 0 == MZ ]} {
	if {[S 24 == @ ]} {emit application/octet-stream}
    }
    if {[S 0 == MZ ]} {
	if {[S 30 == {Copyright\ 1989-1990\ PKWARE\ Inc.} ]} {emit application/x-zip}
    }
    if {[S 0 == MZ ]} {
	if {[S 30 == {PKLITE\ Copr.} ]} {emit application/x-zip}
    }
    if {[S 0 == MZ ]} {
	if {[S 36 == {LHa's\ SFX} ]} {emit application/x-lha}
    }
    if {[S 0 == MZ ]} {emit application/octet-stream}
    if {[S 2 == -lh ]} {
	if {[S 6 == - ]} {emit application/x-lha}
    }
    if {[N i 20 == 0xfdc4a7dc ]} {emit application/x-zoo}
    if {[S 0 == AT&TFORM ]} {emit image/x.djvu}
    if {[S 0 == {\0\0MMXPR3\0} ]} {emit application/x-quark-xpress-3}
    if {[S 0 == CWS ]} {emit application/x-shockwave-flash}
    if {[S 39 == <gmr:Workbook ]} {emit application/x-gnumeric}

    result

    return {}
}
