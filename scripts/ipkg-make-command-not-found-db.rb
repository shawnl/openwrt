#!/usr/bin/ruby
# (C) 2018 Shawn Landden, GPL-2+
#Create the databases (or cache) for command-not-found
#
#Patches are accepted, as well as rewrites.

STDERR.puts("Usage: ipkg-make-command-not-found-db <package_directory>") || Kernel.exit(1) if (ARGV[0] == nil)
Dir.chdir(ARGV[0])

paths = Regexp.new('^\./(?:(?:bin/)|(?:sbin/)|(?:usr/bin/)|(?:usr/sbin/)|(?:usr/games/))')
db = []
arches = Dir.open(".")
arches.each{ |arch|
        next if !File.directory?(arch) || arch == "." || arch == ".."
        feeds = Dir.open(arch)
        feeds.each{ |feed| 
                path = [arch, feed].join("/")
                next if !File.directory?(path) || arch == "." || arch == ".."
                packages = Dir.open(path)
                packages.each{ |package|
                        path = [arch, feed, package].join("/")
                        next if !/.ipk/.match(package)
                        files = `tar -f #{path} -z --to-stdout -x ./data.tar.gz | tar -z --list`.split("\n")
                        files.reject!{ |f|
                                true if Regexp.new('/\Z').match(f)
                        }
                        files.grep(paths).each { |file|
                                if (feed == "packages")
                                        db << "#{/[^\/]*\Z/.match(file)}\xff#{/^[^_]*/.match(package)}"
                                else
                                        db << "#{/[^\/]*\Z/.match(file)}\xff#{/^[^_]*/.match(package)}/#{feed[0]}"
                                end
                        }
                }
        }
}
db.sort!
db.uniq!
out = open("command-not-found.db", "w+")
db.each { |i|
       out.write(i)
       out.putc("\n")
}

