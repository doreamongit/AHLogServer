int avformat_open_input(AVFormatContext **ps, const char *url, AVInputFormat *fmt, AVDictionary **options);
该函数用于打开多媒体数据并且获得一些相关的信息。

ps：函数调用成功之后处理过的AVFormatContext结构体。
file：打开的视音频流的URL。
fmt：强制指定AVFormatContext中AVInputFormat的。这个参数一般情况下可以设置为NULL，这样FFmpeg可以自动检测AVInputFormat。
dictionay：附加的一些选项，一般情况下可以设置为NULL。

avformat_open_input()源代码比较长，一部分是一些容错代码，比如说如果发现传入的AVFormatContext指针没有初始化过，就调用avformat_alloc_context()初始化该结构体；还有一部分是针对一些格式做的特殊处理，比如id3v2信息的处理等等。有关上述两种信息不再详细分析，在这里只选择它关键的两个函数进行分析：
init_input()：绝大部分初始化工作都是在这里做的。
s->iformat->read_header()：读取多媒体数据文件头，根据视音频流创建相应的AVStream。

init_input()作为一个内部函数，竟然包含了一行注释（一般内部函数都没有注释），足可以看出它的重要性。
它的主要工作就是打开输入的视频数据并且探测视频的格式。

梳理一下：
在函数的开头的score变量是一个判决AVInputFormat的分数的门限值，
如果最后得到的AVInputFormat的分数低于该门限值，就认为没有找到合适的AVInputFormat。
FFmpeg内部判断封装格式的原理实际上是对每种AVInputFormat给出一个分数，满分是100分，
越有可能正确的AVInputFormat给出的分数就越高。
最后选择分数最高的AVInputFormat作为推测结果。
score的值是一个宏定义AVPROBE_SCORE_RETRY，我们可以看一下它的定义：

由此我们可以得出score取值是25，即如果推测后得到的最佳AVInputFormat的分值低于25，就认为没有找到合适的AVInputFormat。

整个函数的逻辑大体如下：
（1）当使用了自定义的AVIOContext的时候（AVFormatContext中的AVIOContext不为空，即s->pb!=NULL），
如果指定了AVInputFormat就直接返回，
如果没有指定就调用av_probe_input_buffer2()推测AVInputFormat。
这一情况出现的不算很多，但是当我们从内存中读取数据的时候（需要初始化自定义的AVIOContext），就会执行这一步骤。
（2）在更一般的情况下，如果已经指定了AVInputFormat，就直接返回；
如果没有指定AVInputFormat，就调用av_probe_input_format(NULL,…)根据文件路径判断文件格式。
这里特意把av_probe_input_format()的第1个参数写成“NULL”，是为了强调这个时候实际上并没有给函数提供输入数据，此时仅仅通过文件路径推测AVInputFormat。
（3）如果发现通过文件路径判断不出来文件格式，那么就需要打开文件探测文件格式了，这个时候会首先调用avio_open2()打开文件，然后调用av_probe_input_buffer2()推测AVInputFormat。

av_probe_input_format2()
该函数用于根据输入数据查找合适的AVInputFormat。参数含义如下所示：

pd：存储输入数据信息的AVProbeData结构体。
is_opened：文件是否打开。
score_max：判决AVInputFormat的门限值。只有某格式判决分数大于该门限值的时候，函数才会返回该封装格式，否则返回NULL。

av_probe_input_format2()函数中涉及到一个结构体AVProbeData，用于存储输入文件的一些信息

从av_probe_input_format2()函数中可以看出，av_probe_input_format2()调用了av_probe_input_format3()，
并且增加了一个判断，当av_probe_input_format3()返回的分数大于score_max的时候，才会返回AVInputFormat，否则返回NULL。

av_probe_input_format3()

从函数声明中可以看出，av_probe_input_format3()和av_probe_input_format2()的区别
是函数的第3个参数不同：av_probe_input_format2()是一个分数的门限值，
而av_probe_input_format3()是一个探测后的最匹配的格式的分数值

av_probe_input_format3()根据输入数据查找合适的AVInputFormat。
输入的数据位于AVProbeData中。前文已经提到过，AVProbeData定义如下。

其中
filename是文件路径，
buf存储用于推测AVInputFormat的媒体数据，最后还有个
mime_type保存媒体的类型。

其中buf可以为空，但是其后面无论如何都需要填充AVPROBE_PADDING_SIZE个0（AVPROBE_PADDING_SIZE取值为32，即32个0）。
该函数最主要的部分是一个循环。该循环调用av_iformat_next()遍历FFmpeg中所有的AVInputFormat，
并根据以下规则确定AVInputFormat和输入媒体数据的匹配分数（score，反应匹配程度）

（1）如果AVInputFormat中包含read_probe()，就调用read_probe()函数获取匹配分数（这一方法如果结果匹配的话，一般会获得AVPROBE_SCORE_MAX的分值，即100分）。如果不包含该函数，就使用av_match_ext()函数比较输入媒体的扩展名和AVInputFormat的扩展名是否匹配，如果匹配的话，设定匹配分数为AVPROBE_SCORE_EXTENSION（AVPROBE_SCORE_EXTENSION取值为50，即50分）。
（2）使用av_match_name()比较输入媒体的mime_type和AVInputFormat的mime_type，如果匹配的话，设定匹配分数为AVPROBE_SCORE_MIME（AVPROBE_SCORE_MIME取值为75，即75分）。
（3）如果该AVInputFormat的匹配分数大于此前的最大匹配分数，则记录当前的匹配分数为最大匹配分数，并且记录当前的AVInputFormat为最佳匹配的AVInputFormat。

上述过程中涉及到以下几个知识点：

AVInputFormat->read_probe()

AVInputFormat中包含read_probe()是用于获得匹配函数的函数指针，不同的封装格式包含不同的实现函数。
例如，FLV封装格式的AVInputFormat模块定义（位于libavformat\flvdec.c）如下所示。

其中，read_probe()函数对应的是flv_probe()函数。我们可以看一下flv_probe()函数的定义：

可见flv_probe()调用了一个probe()函数。probe()函数的定义如下。

从probe()函数我们可以看出，该函数做了如下工作：
（1）获得第6至第9字节的数据（对应Headersize字段）并且做大小端转换，然后存入offset变量。
之所以要进行大小端转换是因为FLV是以“大端”方式存储数据，而操作系统是以“小端”方式存储数据，
这一转换主要通过AV_RB32()函数实现。AV_RB32()是一个宏定义，其对应的函数是av_bswap32()。

（2）检查开头3个字符（Signature）是否为“FLV”。

（3）第4个字节（Version）小于5。

（4）第6个字节（Headersize的第1个字节？）为0。

（5）offset取值大于8。

参照FLV文件头的格式可以对上述判断有一个更清晰的认识：
https://img-blog.csdn.net/20150304203241824?watermark/2/text/aHR0cDovL2Jsb2cuY3Nkbi5uZXQvbGVpeGlhb2h1YTEwMjA=/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70/gravity/SouthEast

此外代码中还包含了有关live方式的FLV格式的判断，在这里我们不加探讨。
对于我们打开FLV文件来说，live和is_live两个变量取值都为0。
也就是说满足上述5个条件的话，就可以认为输入媒体数据是FLV封装格式了。
满足上述条件，probe()函数返回AVPROBE_SCORE_MAX（AVPROBE_SCORE_MAX取值为100，即100分），否则返回0（0分）。

av_match_name()是一个API函数，声明位于libavutil\avstring.h，如下所示。
av_match_name()用于比较两个格式的名称。简单地说就是比较字符串。
注意该函数的字符串是不区分大小写的：字符都转换为小写进行比较。

上述函数还有一点需要注意，其中使用了一个while()循环，用于搜索“,”。
这是因为FFmpeg中有些格式是对应多种格式名称的，例如MKV格式的解复用器（Demuxer）的定义如下。

AVInputFormat ff_matroska_demuxer = {
.name           = "matroska,webm",
.long_name      = NULL_IF_CONFIG_SMALL("Matroska / WebM"),
.extensions     = "mkv,mk3d,mka,mks",
.priv_data_size = sizeof(MatroskaDemuxContext),
.read_probe     = matroska_probe,
.read_header    = matroska_read_header,
.read_packet    = matroska_read_packet,
.read_close     = matroska_read_close,
.read_seek      = matroska_read_seek,
.mime_type      = "audio/webm,audio/x-matroska,video/webm,video/x-matroska"
};

从代码可以看出，ff_matroska_demuxer中的
name字段对应“matroska,webm”，
mime_type字段对应“audio/webm,audio/x-matroska,video/webm,video/x-matroska”。
av_match_name()函数对于这样的字符串，会把它按照“,”截断成一个个的名称，然后一一进行比较。

av_match_ext()是一个API函数，声明位于libavformat\avformat.h
（注意位置和av_match_name()不一样），如下所示。

av_match_ext()用于比较文件的后缀。
该函数首先通过反向查找的方式找到输入文件名中的“.”，就可以通过获取“.”后面的字符串来得到该文件的后缀。
然后调用av_match_name()，采用和比较格式名称的方法比较两个后缀。

avio_open2()
有关avio_open2()的分析可以参考文章：FFmpeg源代码简单分析：avio_open2()
https://blog.csdn.net/leixiaohua1020/article/details/41199947

av_probe_input_buffer2()是一个API函数，它根据输入的媒体数据推测该媒体数据的AVInputFormat，
声明位于libavformat\avformat.h，如下所示。

av_probe_input_buffer2()参数的含义如下所示：
pb：用于读取数据的AVIOContext。
fmt：输出推测出来的AVInputFormat。
filename：输入媒体的路径。
logctx：日志（没有研究过）。
offset：开始推测AVInputFormat的偏移量。
max_probe_size：用于推测格式的媒体数据的最大值。

返回推测后的得到的AVInputFormat的匹配分数。


av_probe_input_buffer2()的定义位于libavformat\format.c，如下所示。
av_probe_input_buffer2()首先需要确定用于推测格式的媒体数据的最大值max_probe_size。
max_probe_size默认为PROBE_BUF_MAX（PROBE_BUF_MAX取值为1 << 20，即1048576Byte，大约1MB）。
在确定了max_probe_size之后，
函数就会进入到一个循环中，调用avio_read()读取数据并且使用av_probe_input_format2()（该函数前文已经记录过）推测文件格式。

肯定有人会奇怪这里为什么要使用一个循环，而不是只运行一次？其实这个循环是一个逐渐增加输入媒体数据量的过程。
av_probe_input_buffer2()并不是一次性读取max_probe_size字节的媒体数据，
我个人感觉可能是因为这样做不是很经济，因为推测大部分媒体格式根本用不到1MB这么多的媒体数据。
因此函数中使用一个probe_size存储需要读取的字节数，并且随着循环次数的增加逐渐增加这个值。
函数首先从PROBE_BUF_MIN（取值为2048）个字节开始读取，如果通过这些数据已经可以推测出AVInputFormat，那么就可以直接退出循环了
（参考for循环的判断条件“!*fmt”）；
如果没有推测出来，就增加probe_size的量为过去的2倍（参考for循环的表达式“probe_size << 1”），
继续推测AVInputFormat；如果一直读取到max_probe_size字节的数据依然没能确定AVInputFormat，则会退出循环并且返回错误信息。

AVInputFormat-> read_header()
在调用完init_input()完成基本的初始化并且推测得到相应的AVInputFormat之后，
avformat_open_input()会调用AVInputFormat的read_header()方法
读取媒体文件的文件头并且完成相关的初始化工作。

read_header()是一个位于AVInputFormat结构体中的一个函数指针，
对于不同的封装格式，会调用不同的read_header()的实现函数。
举个例子，当输入视频的封装格式为FLV的时候，会调用FLV的AVInputFormat中的read_header()。
FLV的AVInputFormat定义位于libavformat\flvdec.c文件中，如下所示。

可以看出read_header()指向了flv_read_header()函数。
flv_read_header()的实现同样位于libavformat\flvdec.c文件中，如下所示。

可以看出，函数读取了FLV的文件头并且判断其中是否包含视频流和音频流。
如果包含视频流或者音频流，就会调用create_stream()函数。
create_stream()函数定义也位于libavformat\flvdec.c中，如下所示。

从代码中可以看出，create_stream()调用了API函数avformat_new_stream()创建相应的视频流和音频流。
上面这段解析FLV头的代码可以参考一下FLV封装格式的文件头格式，如下图所示。
https://img-blog.csdn.net/20150304204037946?watermark/2/text/aHR0cDovL2Jsb2cuY3Nkbi5uZXQvbGVpeGlhb2h1YTEwMjA=/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70/gravity/SouthEast

经过上面的步骤AVInputFormat的read_header()完成了视音频流对应的AVStream的创建。
至此，avformat_open_input()中的主要代码分析完毕。

avformat_open_input()作用为打开输入文件，并将输入文件中的数据读入到buf，以及判断输入文件的格式。
例如可以判断是否为flv格式等，并将输入文件格式保存到指针AVFormatContext iformat

可以看到第一个参数,既可以是一个NULL的指针,又可以是由avformat_alloc_context()创建的AVFormatContext对象.
所以在使用这个函数的时候,要么保证ps指向一个已分配的内存.要么为NULL

这种写法是错误的
AVFormatContext *formatContext;

以下两种写法都可以
AVFormatContext *formatContext = NULL;
AVFormatContext *formatContext = avformat_alloc_context();
