#
# Zip file generator - Create a Zip-file from a list of input file names
#
# This implementation is based on the zip file builder of Artur
# Trzewik (http://wiki.tcl.tk/15158), but was simplified, refactored,
# commented and extended, based on Trf and translated to NX; for
# details about the format, see
# http://www.pkware.com/documents/casestudies/APPNOTE.TXT
#
# by Gustaf Neumann (June 2011)
#

package require nx
package require Trf
package provide nx::zip 1.1

namespace eval ::nx::zip {

  nx::Class create Archive {
    #
    # The public interface of the class archive contains the methods
    #
    #   - addFile    (add a file from the filesystem to the archive)
    #   - addString  (add the file-content from a string to the archive)
    #
    #    - writeToZipFile    (produce a Zip file)
    #    - ns_returnZipFile  (return a zip file via AOLserver ns_return) 
    #
    #    - writeToStream     (for already opened and configured 
    #                        output streams
    #

    #
    # Add a file from the file system to the zip archive
    #
    :public method addFile {inputFileName outputFileName:optional} {
      # inputFileName - source file to archive
      # outputFileName - name of the file in the archive
      if {![file readable $inputFileName] || [file isdirectory $inputFileName]} {
	error "filename $inputFileName does not belong to a readable file"
      }
      if {![info exists outputFileName]} {set outputFileName $inputFileName}
      lappend :files file $inputFileName $outputFileName
    }

    #
    # Add a filecontent provided as string to the zip archive
    #
    :public method addString {string outputFileName} {
      # string - content to be added
      # outputFileName - name of the file in the archive
      lappend :files string $string $outputFileName
    }

    #
    # Write the added files to a zip file
    #
    :public method writeToZipFile {zipFileName} {
      set fout [open $zipFileName w]
      fconfigure $fout -translation binary -encoding binary
      :writeToStream $fout
      close $fout
    }

    #
    # return the added files via aolserver/NaviServer to the client
    #
    :public method ns_returnZipFile {zipFileName} {
      ns_write "HTTP/1.0 200 OK\r\nContent-type: application/zip\r\n"
      ns_write "Content-Disposition: attachment;filename=\"$zipFileName\"\r\n"
      ns_write "\r\n"
      set channel [ns_conn channel]
      fconfigure $channel -translation binary
      :writeToStream $channel
      # aolserver/NaviServer closes the channel automatically
    }

    #
    # Write the added files to an already open stream
    #
    :public method writeToStream {outputStream} {
      set :outputStream $outputStream

      #
      # Write all files to the outout stream
      #
      set descriptionList [list]
      foreach {type in fnOut} ${:files} {
	lappend descriptionList [:addSingleFile $type $in $fnOut]
      }
      #
      # we have no 
      #  - archive description header
      #  - archive extra data record
      #
      # Add the central directory
      #
      set :cdOffset ${:written}
      foreach {type in fnOut} ${:files} desc $descriptionList {
	array set "" $desc
       
	# For every file, it contains again part of the information of
	# the local file headers, but with some additional information
	# such as a the "version made by", comment, ...

	set comment ""
	set platform 0 ;# dos/windows
	#if {$::tcl_platform(platform) ne "windows"} {
	#  set platform 3 ;# unix 
	#}

	# central file header signature
	binary scan \x02\x01\x4B\x50 I CFH_SIG
	:writeLong $CFH_SIG

	# version made by (os + zip version)
	:writeShort [expr { (($platform << 8) | 20) }]
 
	:writeFileHeaderBlock $desc

	# file comment length
	:writeShort [string length $comment]
	# disk number start
	:writeShort 0
	# internal file attributes
	:writeShort 0
	# external file attributes
	:writeLong 0
    
	# relative offset of local header
	:writeLong $(offset)
    	# file name
	:writeString $(fileNameInternal)
    
	:writeExtraFieldUPATH $(fileName) $(fileNameInternal)
   
	# file comment
	:writeString $comment
      }

      set :cdLength [expr {${:written} - ${:cdOffset}}]

      #
      # End of Central Directory record
      #
      binary scan \x06\x05\x4B\x50 I EOCD
      :writeLong $EOCD
    
      # disk numbers
      :writeShort 0
      :writeShort 0
    
      # number of entries
      set filenum [expr {[llength ${:files}] / 3}]
      :writeShort $filenum
      :writeShort $filenum
    
      # length and location of CD
      :writeLong ${:cdLength}
      :writeLong ${:cdOffset}
    
      # zip file comment
      set comment ""

      # comment length
      :writeShort [string bytelength $comment]
      :writeString $comment
    }

    #
    # Constructor
    #
    :method init {} {
      set :files [list]
      set :cdLength 0
      set :cdOffset 0
      set :written 0
    }

    #
    # Output content file to the output stream
    #
    :method addSingleFile {type in fnOut} {
      set (offset) ${:written}
    
      if {$type eq "file"} {
	set fdata [open $in r]
	fconfigure $fdata -encoding binary -translation binary
	set data [read $fdata]
	close $fdata
	set mtime [file mtime $in]
      } else {
	set data [encoding convertto utf-8 $in]
	set mtime [clock seconds]
      }
      
      #
      # local file header
      #
      binary scan \x04\x03\x4B\x50 I LFH_SIG
      :writeLong $LFH_SIG

      set datacompressed [string range [::zip -mode compress -- $data] 2 end-4]

      set (dosTime) [:toDosTime $mtime]
      set (crc)   [::crc-zlib -- $data]
      set (csize) [string length $datacompressed]
      set (size)  [string length $data]
      set (fileName) [encoding convertto utf-8 $fnOut]
      set (fileNameInternal) $(fileName)
      #set (fileNameInternal) [encoding convertto cp850 $fnOut]
      set (extraFieldLength) [expr {9+[string length $(fileName)]}]
      
      :writeFileHeaderBlock [array get ""]

      # file name
      :writeString $(fileNameInternal)
      
      :writeExtraFieldUPATH $(fileName) $(fileNameInternal)

      #
      # file data
      #
      :writeString $datacompressed
    
      return [array get ""]
    }

    :method writeFileHeaderBlock {pairs} {
      array set "" $pairs

      # version needed to extract
      :writeShort 20

      # general pupose bit flag
      :writeShort [expr {1<<11}]
      #:writeShort 0

      # compression method
      :writeShort 8
    
      # last modification time and date
      :writeLong $(dosTime)

      :writeString $(crc)
      :writeLong $(csize)
      :writeLong $(size)
    
      # file name length
      :writeShort [string length $(fileNameInternal)]
    
      # extra field length
      :writeShort $(extraFieldLength)
    }
  
    #
    # Convert the provided time stamp to DOS time.
    #
    :method toDosTime {time} {
      foreach {year month day hour minute second} \
	  [clock format $time -format "%Y %m %e %k %M %S"] {}

      set RE {^0([0-9]+)$}
      regexp $RE $year . year
      regexp $RE $month . month
      regexp $RE $day . day
      regexp $RE $hour . hour
      regexp $RE $minute . minute
      regexp $RE $second . second

      set value [expr {(($year - 1980) << 25) | ($month << 21) | 
		       ($day << 16) | ($hour << 11) | ($minute << 5) |
		       ($second >> 1)}]
      return $value
    }

    #
    # Extra field UPath: Info-ZIP Unicode Path Extra Field
    #
    :method writeExtraFieldUPATH {fileName fileNameInternal} {
      # extra field UPATH
      binary scan \x70\x75 S EPEF
      :writeShort $EPEF
      :writeShort [expr {5+[string length $fileName]}]
      :writeByte 1
      :writeString [::crc-zlib $fileNameInternal]
      :writeString $fileName
    }
    
    #
    # Write the provided integer in binary form as a long value (32 bit)
    #
    :method writeLong {long:integer} {
      puts -nonewline ${:outputStream} [binary format i $long]
      incr :written 4
    }

    #
    # Write the provided integer in binary form as a short value (16 bit)
    #
    :method writeShort {short:integer} {
      puts -nonewline ${:outputStream} [binary format s $short]
      incr :written 2
    }

    #
    # Write the provided integer in binary form as a single byte (8 bit)
    #
    :method writeByte {byte:integer} {
      puts -nonewline ${:outputStream} [binary format c $byte]
      incr :written 1
    }

    #
    # Write the provided string to the output stream and increment
    # byte counter.
    #
    :method writeString {string} {
      puts -nonewline ${:outputStream} $string
      incr :written [string length $string]
    }
    :method writeStringBytes {string} {
      puts -nonewline ${:outputStream} $string
      incr :written [string bytelength $string]
    }

  }
}

if {0} {
  set z [::nx::zip::Archive new]
  $z addFile README.aol 
  $z addFile COPYRIGHT
  $z addFile nsfUtil.o 
  $z addFile doc/nx.css
  $z addString "This is a file\nthat может be from a string\n"  README
  $z addString "-Avec 3,2% des parts de marché, la France est le sixième plus grand pays fournisseur de l’Autriche. " franz.txt
  $z writeToZipFile /tmp/test.zip
  $z destroy
}
