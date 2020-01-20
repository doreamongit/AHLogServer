在使用libavdevice之前，必须先运行avdevice_register_all()对设备进行注册，否则就会出错。avdevice_register_all()的注册方式和av_register_all()、avcodec_register_all()这几个函数是类似的。

/*
这个avcodec_register_all(),avcodec_register_all()已经不再需要了，这些注册函数都不需要我们手动调用了,组件可以直接用
*/
//avcodec_register_all();
