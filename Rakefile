# -*- ruby -*-

require 'rake/clean'

java = RUBY_PLATFORM =~ /java/
macruby = defined?(RUBY_ENGINE) && RUBY_ENGINE == "macruby"

require 'rubygems'

if java
  CLEAN.concat Dir["vendor/zxing/core/core.jar"]
  CLEAN.concat Dir["vendor/zxing/javase/javase.jar"]
else
  CLEAN.concat Dir["**/*.a"]
  CLEAN.concat Dir["**/*.so"]
  CLEAN.concat Dir["**/*.bundle"]
  CLEAN.concat Dir["**/*.dylib"]
  CLEAN.concat Dir["**/*.pyc"]
  CLEAN.concat Dir["lib/zxing/Makefile"]
  CLEAN.concat Dir["lib/zxing/zxing.o"]
  CLEAN.concat Dir["**/.sconsign.dblite"]
end
CLEAN.concat Dir["**/build"]

shared_ext = ".so"
Dir["lib/zxing/zxing.*"].each do |file|
  case file
  when %r{\.so$}; shared_ext = ".so"
  when %r{\.dylib$}; shared_ext = ".dylib"
  when %r{\.bundle$}; shared_ext = ".bundle"
  end
end

file "vendor/zxing" do
  sh "git submodule update --init"
end

task :compile => "vendor/zxing"

task :clean do
  if File.exist? "vendor/zxing/cpp/build" 
    Dir.chdir "vendor/zxing/cpp" do
      sh "python scons/scons.py -c"
    end
  end
  if java
    if File.exist? "vendor/zxing/core/build"
      Dir.chdir "vendor/zxing/core" do
        sh "mvn clean"
      end
    end
    if File.exist? "vendor/zxing/javase/build" 
      Dir.chdir "vendor/zxing/javase" do
        sh "mvn clean"
      end
    end
  end
end

zxing = "vendor/zxing"

mvn_opts = "-Dmaven.javadoc.skip=true -DskipTests=true"

subdirs = []
subdirs += [:aztec, :datamatrix, :negative, :oned]
subdirs += [:rss, :"rss/expanded"] if java
subdirs += [:qrcode, :pdf417]
if java
  if File.exists? "#{zxing}/core"
    file "#{zxing}/core/target/core-2.2-SNAPSHOT.jar" do
      chdir "#{zxing}/core" do
        sh "mvn #{mvn_opts} package"
      end
    end
    file "lib/zxing/core.jar" => "#{zxing}/core/target/core-2.2-SNAPSHOT.jar" do
      cp "#{zxing}/core/target/core-2.2-SNAPSHOT.jar", "lib/zxing/core.jar"
    end
  end

  if File.exists? "#{zxing}/javase"
    file "#{zxing}/javase/target/javase-2.2-SNAPSHOT.jar" =>
      "#{zxing}/core/target/core-2.2-SNAPSHOT.jar" do
      chdir "#{zxing}/javase" do
        sh "mvn #{mvn_opts} package"
      end
    end
    file "lib/zxing/javase.jar" => "#{zxing}/javase/target/javase-2.2-SNAPSHOT.jar" do
      cp "#{zxing}/javase/target/javase-2.2-SNAPSHOT.jar", "lib/zxing/javase.jar"
    end
  end

  namespace :compile do
    task :core do
      sh "(cd #{zxing}/core && mvn #{mvn_opts} package) && cp #{zxing}/core/target/core-2.2-SNAPSHOT.jar lib/zxing/core.jar"
    end
    task :javase do
      sh "(cd #{zxing}/javase && mvn #{mvn_opts} package) && cp #{zxing}/javase/target/javase-2.2-SNAPSHOT.jar lib/zxing/javase.jar"
    end
  end

  desc "compile zxing if jars don't exist"
  task :compile => [ "lib/zxing/core.jar", "lib/zxing/javase.jar" ]

  desc "force jar recreation"
  task :recompile => [ "compile:core", "compile:javase" ]
end

if macruby
  rule '.o' => '.rb' do |t|
    sh "macrubyc -c #{t.source}"
  end

  file "vendor/zxing/objc/build/Debug/zxing.bundle" do
    Dir.chdir "vendor/zxing/objc" do
      raise "implement"
    end
  end
  file "lib/zxing/objc/zxing.bundle" => "vendor/zxing/objc/build/Debug/zxing.bundle" do
    cp "vendor/zxing/objc/build/Debug/zxing.bundle", "lib/zxing/objc/zxing.bundle"
  end
  task :xcode do
    Dir.chdir "vendor/zxing/objc" do
      sh "xcodebuild -project osx.xcodeproj -configuration Debug"
    end
  end
  desc "compile zxing module"
  task :compile => [ :xcode, "lib/zxing/objc/zxing.bundle" ]
end

if !java && !macruby
  file "vendor/zxing/cpp/build/libzxing.a" =>
    Dir["vendor/zxing/cpp/core/src/**/*.{h,cpp}"] do
    Dir.chdir "vendor/zxing/cpp" do
      sh "python scons/scons.py DEBUG=false PIC=yes lib"
    end
  end
  file "lib/zxing/Makefile" => [ "lib/zxing/extconf.rb",
                                 "vendor/zxing/cpp/build/libzxing.a" ] do
    Dir.chdir "lib/zxing" do
      ruby "extconf.rb"
    end
  end
  file "lib/zxing/zxing#{shared_ext}" => [ "lib/zxing/Makefile",
                                           "lib/zxing/zxing.cc",
                                           "vendor/zxing/cpp/build/libzxing.a" ] do
    sh "cd lib/zxing && make"
  end
  task :recompile do
    file("vendor/zxing/cpp/build/libzxing.a").execute
    rm_f "lib/zxing/zxing#{shared_ext}"
    file("lib/zxing/zxing#{shared_ext}").execute
  end
  desc "compile zxing shared library"
  task :compile => "lib/zxing/zxing#{shared_ext}"
end

namespace :zxing do
  namespace :test do
    subdirs.each do |subdir|
      namespace subdir do
        desc "run #{subdir} tests"
        task :run do
          args = [
                  # "ruby", "-Ilib",
                  "test/vendor.rb" ] +
            Dir["vendor/zxing/**/#{subdir}/*BlackBox*TestCase.java"]
          args.unshift "valgrind" if ENV["valgrind"]
          args.unshift "env", "EXPLICIT_LUMINANCE_CONVERSION=true"
          sh args.join(" ")
        end
      end
      desc "compile and run #{subdir} tests"
      task subdir => [ :compile, "test:#{subdir}:run" ]
    end
    task :run => subdirs.map { |subdir| "test:#{subdir}:run" }
  end

  desc "run all the zxing tests (optionally, only those maching [pattern])"
  task :test, [ :pattern ] => :compile do |t, args|
    if args[:pattern]
      args = ["ruby", "-Ilib", "test/vendor.rb", args[:pattern]]
      args.unshift "valgrind" if ENV["valgrind"]
      args.unshift "env", "EXPLICIT_LUMINANCE_CONVERSION=true"
      sh args.join(" ")
    else
      subdirs.each { |subdir| task("zxing:test:#{subdir}:run").execute }
    end
  end
end

task(:default).clear
task :default => :compile

if java
  task :gem => [ "lib/zxing/core.jar", "lib/zxing/javase.jar" ]
end

# manifest stuff:
# egrep -v '(/actionscript/|/zxingorg/|/zxing.appspot|symbian|/rim/|javame|zxing/jruby|/iphone/|csharp/|/test/|/bug/|/android|.git|.valgrind|.xcodeproj|vendor/zxing/core)' Manifest.txt | less
