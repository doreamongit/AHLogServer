avformat_find_stream_info()
该函数可以读取一部分视音频数据并且获得一些相关的信息。
该函数主要用于给每个媒体流（音频/视频）的AVStream结构体赋值。我们大致浏览一下这个函数的代码，
会发现它其实已经实现了解码器的查找，解码器的打开，视音频帧的读取，视音频帧的解码等工作。
换句话说，该函数实际上已经“走通”的解码的整个流程。

1.查找解码器：find_decoder()
2.打开解码器：avcodec_open2()
3.读取完整的一帧压缩编码的数据：read_frame_internal()
注：av_read_frame()内部实际上就是调用的read_frame_internal()。
4.解码一些压缩编码数据：try_decode_frame()


从try_decode_frame()的定义可以看出，该函数首先判断视音频流的解码器是否已经打开，
如果没有打开的话，先打开相应的解码器。
接下来根据视音频流类型的不同，调用不同的解码函数进行解码：
视频流调用avcodec_decode_video2()，
音频流调用avcodec_decode_audio4()，
字幕流调用avcodec_decode_subtitle2()。
解码的循环会一直持续下去直到满足了while()的所有条件。
while()语句的条件中有一个has_codec_parameters()函数，
用于判断AVStream中的成员变量是否都已经设置完毕。
该函数在avformat_find_stream_info()中的多个地方被使用过。

estimate_timings()位于avformat_find_stream_info()最后面，
用于估算AVFormatContext以及AVStream的时长duration。

从estimate_timings()的代码中可以看出，有3种估算方法：
（1）通过pts（显示时间戳）。该方法调用estimate_timings_from_pts()。
它的基本思想就是读取视音频流中的结束位置AVPacket的PTS和起始位置AVPacket的PTS，两者相减得到时长信息。
（2）通过已知流的时长。该方法调用fill_all_stream_timings()。
它的代码没有细看，但从函数的注释的意思来说，应该是当有些视音频流有时长信息的时候，直接赋值给其他视音频流。
（3）通过bitrate（码率）。该方法调用estimate_timings_from_bit_rate()。
它的基本思想就是获得整个文件大小，以及整个文件的bitrate，两者相除之后得到时长信息。

estimate_timings_from_bit_rate()

从代码中可以看出，该函数做了两步工作：
（1）如果AVFormatContext中没有bit_rate信息，就把所有AVStream的bit_rate加起来作为AVFormatContext的bit_rate信息。
（2）使用文件大小filesize除以bitrate得到时长信息。具体的方法是：
AVStream->duration=(filesize*8/bit_rate)/time_base
PS：
1）filesize乘以8是因为需要把Byte转换为Bit
2）具体的实现函数是那个av_rescale()函数。x=av_rescale(a,b,c)的含义是x=a*b/c。
3）之所以要除以time_base，是因为AVStream中的duration的单位是time_base，注意这和AVFormatContext中的duration的单位（单位是AV_TIME_BASE，固定取值为1000000）是不一样的。
