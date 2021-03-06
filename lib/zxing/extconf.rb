require 'mkmf'

zxing = [ File.dirname(__FILE__), "..", "..", "vendor", "zxing" ]
zxing_java_core = zxing + [ "core" ]
zxing_java_javase = zxing + [ "javase" ]
zxing_cpp = zxing + [ "cpp" ]

cpp_include = File.join File.expand_path(File.join zxing_cpp + [ "core", "src" ])

lib = zxing_cpp + ["build"]
lib = File.expand_path File.join(*lib)
lib = Dir[lib+"/libzxing.a"][0]

$CFLAGS = %(-I#{cpp_include})
$DLDFLAGS = %(-lstdc++ #{lib})
if Dir["/usr/lib/libiconv.*"].size > 0
  $DLDFLAGS << %( -liconv)
end

create_makefile 'zxing'
