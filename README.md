# RAC介绍与初步使用

## RAC介绍

**RAC** 指的就是[RactiveCocoa](https://github.com/ReactiveCocoa) ，是最初由GitHub团队开发的一套基于Cocoa的FRP框架。FRP即Functional Reactive Programming（函数式响应式编程），能够通过信号提供大量方便的事件处理方案，让我们更简单粗暴地去处理事件，现在分为 ReactiveObjC（OC） 和 ReactiveSwift（swift）。

在iOS开发中，页面属性的控制、不同类之间的传值、数据的交互是重要内容，我们常接触到的方式主要是block、delegate代理、KVO、notification这几种方法。在RAC中，提供了大量具备替代KVO、delegate代理、通知、点击事件、计时器timer等各种方法。依据响应式函数编程，RAC方法本身更加简明，通过提供信号的方式（RACSignal）来捕捉当前以及未来的属性值变化，可直接在block中将逻辑代码加入其中，使得代码紧凑，更加直观。同时，在RAC中，万物皆消息，特别是关于冷热信号的处理与使用，都给RAC的学习造成了一定的阻碍。本次我们只是介绍一下RAC的基础使用，底层内容留待私下了解学习。

## RAC简单使用

### 1、RAC的安装

RAC针对不同的语言有不同的库，主要是ReactiveCocoa、ReactiveObjC、ReactiveSwift和ReactiveObjCBridge。其中：

* ReactiveCocoa 包含了OC和swift代码
* ReactiveObjC 纯OC代码建议使用（后面我们所使用的即是此库）
* ReactiveSwift 纯swift的代码就可以使用它了
* ReactiveObjCBridge OC和swift混编就要用到它了

我们比较常见的就是Cocoa，但是如果是纯OC的代码，还是建议使用ObjC，至于纯Swift建议不要使用Swift，据传说是因为很难用。这里，我们通过CocoaPads安装ReactiveObjC。

### 2、RAC的简单使用

上面说过了，在RAC中，万物皆消息。我们首先写一个简单的RAC使用用例。
在RAC中，RAC里最常见和常用的类：RACSignal(信号类)。RACSignal创建的信号是一个冷信号，然后通过订阅者订阅这个信号然后变为热信号，最后发送信号，这就是一个完整的流程。下面我们通过代码实现这个流程

``` OC
    //1、创建信号
    @weakify(self);
    RACSignal *signal = [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        @strongify(self);
        self.nowSubscriber = subscriber;
        //3、发送消息
        [subscriber sendNext:@"messgae"];
        [subscriber sendNext:@"messgae 1"];
        return [RACDisposable disposableWithBlock:^{
        }];
    }];
```

下面需要订阅信号，才会收到信号发送的消息

``` OC
//2、订阅信号。返回的是RACDisposable
    RACDisposable *disposeAble = [signal subscribeNext:^(id  _Nullable x) {
        NSLog(@"信号发送的消息：%@",x);
    }];
    //取消订阅.取消订阅之后，订阅者就不会再收到消息
    [disposeAble dispose];
```

RACSubscriber 是订阅者，用于发送信号，这是一个协议，不是一个类，只要遵守这个协议，并且实现方法才能成为订阅者。通过create创建的信号，都有一个订阅者，帮助他发送数据。
RACDisposable:用于取消订阅或者清理资源，当信号发送完成或者发送错误的时候，就会自动触发它。
可以看到的是里面有两个Block：
创建信号的block：是在订阅信号时被调用，如果不订阅信号的话，就永远不会被调用。
订阅信号的block：是在发送信号时被调用，如果不发送信号的话，也是不会被调用的。

### 3、RAC在实际开发中的应用

1. UITextField
2. Delegate
3. UIControl
4. KVO
5. NSNotification
6. 定时器

## RAC的高级使用

1. 其他信号类RACSuject、RACReplaySubject
2. RACCommand的使用
3. 数据绑定
4. RAC中的集合类型（RACTuple、RACSequence）
5. 常用的操作rac_leftSeletor、map、fillter
6. 常用的宏

## RAC的缺点

RAC中大量使用了block，需要特别注意内存问题，稍有不慎既有可能造成内存泄露
RAC基于响应式编程和链式编程思维，需要转换现有编程方式，同时要求团队成员对RAC均有一定程度了解，否则后期维护困难
RAC改变了现有编程方式，对苹果的接口逻辑进行了进一步集成封装，方便开发的同时也会造成一定的局限性

[RAC的一些坑](https://www.dazhuanlan.com/2019/10/11/5d9faf91af2da/?__cf_chl_jschl_tk__=48171d75b1c916363461c39d8e9d8d3a1998a4b8-1584606026-0-AYU4G-AbemhjVsM3Z8ngUg2P5iIFjRoXiuOa75xJMii0Xx03ty9EVcGACsppqRoE3dauWNePE61UE75OSvwhdjFCB_6G_GW9saoLphdSAs6rvFrQROyb0p1M2a0fvPurYlJGFMEwDtcY_FBuPk6UuSE4dJpp8O-6iXp0_7Z2Tosabdo_C29Ke1DKznYedmacU9oMx6iS9n3oMjBD9ps-nliHmoz0bdhUriHQG5hyyl3e_2rVcuvf_ahJaSK_JAdHHZrb1btKVYKz57OS4GnvcbgACTm7Xmo5OD65w05-m-T0zDRiLzviZYFTH007JL3knw)

[RAC使用中遇到的坑](https://www.cnblogs.com/codetime/p/6226137.html)

[RAC 常用Api](https://www.jianshu.com/p/a4fefb434652)

[RAC中的冷热信号底层分析](https://www.jianshu.com/p/21beb4c59bcc)

[RAC中的冷热信号](https://www.jianshu.com/p/dad4eebe7b53)
