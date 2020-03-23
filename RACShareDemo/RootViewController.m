//
//  RootViewController.m
//  RACShareDemo
//
//  Created by zhaojingyu on 2020/3/16.
//  Copyright © 2020 Shoufuyou. All rights reserved.
//

#import "RootViewController.h"
#import <RACReturnSignal.h>
@interface RootViewController ()
@property (nonatomic, strong) id<RACSubscriber> nowSubscriber;
@property (weak, nonatomic) IBOutlet UITextField *inputOne;
@property (weak, nonatomic) IBOutlet UITextField *inputTwo;
@property (weak, nonatomic) IBOutlet UILabel *infoLabel;
@property (weak, nonatomic) IBOutlet UIButton *settingBtn;
@property (weak, nonatomic) IBOutlet UIButton *sendBtn;
@property (weak, nonatomic) IBOutlet UIButton *goBtn;

@end

@implementation RootViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self configUI];
//    [self normalSignalDemo];
//    [self textFieldDemo];
//    [self delegateDemo];
//    [self controlDemo];
//    [self kvoDemo];
//    [self notificationDemo];
//    [self timerDemo];
    
    [self racDemo];
}
///MARK:-- 配置UI
-(void)configUI{
}
///MARK:-- 信号的使用流程
-(void)normalSignalDemo{
    //1、创建信号
//    @weakify(self);
    RACSignal *signal = [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
//        @strongify(self);
//        self.nowSubscriber = subscriber;//这里会引用+1，导致订阅者不会被销毁
        //3、发送消息
        [subscriber sendNext:@"messgae"];
        
        [subscriber sendNext:@"messgae 1"];
        //会自动取消订阅并销毁
        return [RACDisposable disposableWithBlock:^{
            NSLog(@"disposableWithBlock");
            //这里什么时候调用呢：
            /*
             1 订阅者被销毁
             2 RACDisposable 调用dispose取消订阅
             */
        }];
    }];
    
    //2、订阅信号。返回的是RACDisposable
    RACDisposable *disposeAble = [signal subscribeNext:^(id  _Nullable x) {
        NSLog(@"信号发送的消息：%@",x);
    }];
    //取消订阅.取消订阅之后，订阅者就不会再收到消息。
    [disposeAble dispose];
}
///MARK:-- 输入框
-(void)textFieldDemo{
    //获取输入框输入的内容
    [self.inputOne.rac_textSignal subscribeNext:^(NSString * _Nullable x) {
        NSLog(@"input:%@",x);
    }];
    
}
///MARK:-- 代理
-(void)delegateDemo{
    self.inputOne.delegate = self;
    [[self rac_signalForSelector:@selector(textFieldDidBeginEditing:) fromProtocol:@protocol(UITextFieldDelegate)] subscribeNext:^(RACTuple * _Nullable x) {
        NSLog(@"benginInput:%@",x);
    }];
}
///MARK:-- 点击事件
-(void)controlDemo{
    [[self.goBtn rac_signalForControlEvents:UIControlEventTouchUpInside] subscribeNext:^(__kindof UIControl * _Nullable x) {
        NSLog(@"go按钮被点击:%@",x);
    }];
}
///MARK:-- kvo
-(void)kvoDemo{
    [[self.inputOne rac_valuesForKeyPath:@"text" observer:self] subscribeNext:^(id  _Nullable x) {
        NSLog(@"kvo:%@",x);
    }];
}
///MARK:-- 通知
-(void)notificationDemo{
    //代替通知
    //takeUntil会接收一个signal,当signal触发后会把之前的信号释放掉
    [[[[NSNotificationCenter defaultCenter] rac_addObserverForName:UIKeyboardDidShowNotification object:nil] takeUntil:self.rac_willDeallocSignal] subscribeNext:^(id x) {
        NSLog(@"键盘弹出");
    }];
    
    //这个写法有个问题,这样子写信号不会被释放,当你再次收到键盘弹出的通知时他会叠加上次的信号进行执行,并一直叠加下去,所以我们在用上面的写法
    //    [[[NSNotificationCenter defaultCenter] rac_addObserverForName:UIKeyboardDidShowNotification object:nil] subscribeNext:^(id x) {
    
    //        NSLog(@"键盘弹出");

    //    }];
    
    //这里这样写只是为了给大家开拓一种思路,selector的方法可以应需求更改,即当这个方法执行后,产生一个信号告知控制器释放掉这个订阅的信号
//    RACSignal * deallocSignal = [self rac_signalForSelector:@selector(viewWillDisappear:)];
//
//    [[[[NSNotificationCenter defaultCenter] rac_addObserverForName:@"haha" object:nil] takeUntil:deallocSignal] subscribeNext:^(id x) {
//
//        NSLog(@"haha");
//
//    }];
}
///MARK:-- 定时器
-(void)timerDemo{
    //五秒后执行一次
    [[RACScheduler mainThreadScheduler]afterDelay:5 schedule:^{
        NSLog(@"五秒后执行一次");
    }];
    //每隔两秒执行一次
    //这里要加takeUntil条件限制一下否则当控制器pop后依旧会执行
//    [[[RACSignal interval:2 onScheduler:[RACScheduler mainThreadScheduler]] takeUntil:self.rac_willDeallocSignal ] subscribeNext:^(id x) {
//        NSLog(@"每两秒执行一次");
//    }];
    
    #pragma mark -- RACScheduler 线程相关
    /*
     定时器和线程密切相关。RAC也有自己的一套线程操作。
     RACScheduler  信号调度器，是一个线性执行队列，rac中的信号可以在RACScheduler上执行任务、发送结果，底层用GCD封装的。
     */
//    [self scheduleDemo];
    
}
-(void)scheduleDemo{
    
    #pragma mark -- 异步线程操作信号https://www.cnblogs.com/110-913-1025/p/11872203.html
    RACSignal *signal  = [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        NSLog(@"info thread:%@ current scheduler:%@",[NSThread currentThread],[RACScheduler currentScheduler]); //主线程
        [subscriber sendNext:@"info"];
        return  nil;
    }];
    //主线程
    NSLog(@"info thread out:%@ current scheduler:%@",[NSThread currentThread],[RACScheduler currentScheduler]);
    
    //我们让信号在一个异步线程上执行
    [[signal deliverOn:[RACScheduler schedulerWithPriority:RACSchedulerPriorityDefault]] subscribeNext:^(id  _Nullable x) {
        NSLog(@"info thread inner:%@ current:%@",[NSThread currentThread],[RACScheduler currentScheduler]);
        NSLog(@"info1");
    }];
    
}
///MARK:-- 按钮事件
- (IBAction)sendSignal:(id)sender {
//    [self.nowSubscriber sendNext:@"messgae 2"];
    self.inputOne.text = @"点击了设置";
    self.infoLabel.text = @"点击了设置";
}
#pragma mark -- RAC的高级使用
-(void)racDemo{
//    [self otherSignal];
    [self commandDemo];
//    [self bindData];
//    [self racDataDemo];
//    [self racOperateUse];
//    [self definesUse];
}
///MARK 其他类型的信号
-(void)otherSignal{
    //1、RACSuject
    //RACSignal类只能创建信号，无法发送信号。RACSuject既可以发送信号，又可以订阅信号,而且可以多次订阅，但是只能先订阅后发送。可以替换代理
    /*
     如。AView有一个属性RACSuject，点击AView上的按钮的时候，BView需要获取到信息。
     那么就可以在BView中初始化AView的RACSuject，并订阅信号，AViewd被点击的时候，RACSuject发送信号，这是BView就可以收到信息
     
     */
    RACSubject *sub = [RACSubject subject];
//    [sub sendNext:@"subjecr"];

    //订阅信号
    [sub subscribeNext:^(id  _Nullable x) {
        NSLog(@"订阅信息：%@",x);
    }];
   
    [sub sendNext:@"subject2"];

    //RACSuject，只会订阅到在订阅之后发送的信号，订阅之前的信号无法获取
    [sub subscribeNext:^(id  _Nullable x) {
         NSLog(@"订阅信息2：%@",x);
     }];
    //发送信号。必须放到订阅信号之后。如果在订阅信号之前，获取所有的发送信号的信息，那么就要用到RACReplaySubject
    [sub sendNext:@"subject"];
    

    //2、RACReplaySubject。每次订阅的时候，就会把之前的所有信号重新发送一次
    
    RACReplaySubject *replay = [RACReplaySubject subject];
    
    [replay sendNext:@"replay 1"];
    
    [replay sendNext:@"replay 2"];

    [replay subscribeNext:^(id  _Nullable x) {
        NSLog(@"订阅信息 replay ： %@",x);
    }];
    
    [replay sendNext:@"replay 3"];
    
    [replay subscribeNext:^(id  _Nullable x) {
        NSLog(@"订阅信息 replay2 ： %@",x);
    }];

    [replay sendNext:@"replay 4"];
    
}
///MARK 命令
-(void)commandDemo{
    RACCommand *command = [[RACCommand alloc] initWithSignalBlock:^RACSignal * _Nonnull(id  _Nullable input) {
    
        NSLog(@"command:%@",input);
        return [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
            //这里订阅者发送的信息谁来接受呢?
            [subscriber sendNext:@"command subscriber"];
            
            [subscriber sendCompleted];
            return nil;
        }];
    }];

#pragma mark -- 命令执行1
    //    execute 返回的是RACSignal，我们command内部返回的RACSignal就通过execute接受
    //    信号被订阅，变为热信号
    /*
     [command execute:@"命令"];
     [[command execute:@"命令"] subscribeNext:^(id  _Nullable x) {
     NSLog(@"command signal :%@",x);
     }];
     
     */
    
#pragma mark -- 命令执行2
    //还有别的方法可以拿到。但是和上面不同的是，这里拿到的x是一个对象RACDynamicSignal。具体为什么，底层代码研究一下
    /*
     [command.executionSignals subscribeNext:^(id  _Nullable x) {
         NSLog(@"command executionSignals :%@",x);
         [x subscribeNext:^(id  _Nullable x) {
             NSLog(@"executionSignals signal:%@",x);
         }];
     }];
     
     [command execute:@"命令"];
     
     */

#pragma mark -- 命令执行3
    //上面的获取信号是不是一波三折，没有关系，还有第三种方法
    /*
     [command.executionSignals.switchToLatest subscribeNext:^(id  _Nullable x) {
          NSLog(@"command signal:%@",x);
      }];
      [command execute:@"命令"];
     */
 
//    switchToLatest是获取最新信号订阅信息，下面我们通过一个例子看一下
    [self switchToLastDemo];
    
#pragma mark -- 命令执行4
    [command.executing subscribeNext:^(NSNumber * _Nullable x) {
        if ([x boolValue]) {
            NSLog(@"running");
        }else{
            NSLog(@"stop");
        }
    }];
    
    [command execute:@"命令"];
    /*
     //在上面的过程中，我们发现有两点不太对：
     //
     //1、刚运行的时候就来了一次stop，这个不是我们想要的
     //2、并没有结束，但其实我们已经完成了
     在command的block我们可以注意到，我们在signal的block中只发送了数据，并没有告诉外界发送完成了，所以就导致了，一直没发送完成，所以我们在发送数据之后加上[subscriber sendCompleted];
     
     来看第1个问题，为什么第一次就执行结束了，这次的判断不是我们想要的
    这个时候我需要用到一个方法skip，这个方法后面有一个参数，填的就是忽略的次数，我们这个时候只想忽略第一次， 所以就填1
     
     [[command.executing skip:1] subscribeNext:^(NSNumber * _Nullable x) {
            if ([x boolValue]) {
                NSLog(@"running");
            }else{
                NSLog(@"stop");
            }
     }];
     除了skip，RAC中还有很多类似的方法，如
     filter过滤某些
     ignore忽略某些值
     startWith从哪里开始
     skip跳过（忽略）次数
     take取几次值 正序
     takeLast取几次值 倒序
     */
    
    /*
     虽然ReactiveCocoa的官方说过RACSubject较为灵活，所以建议少用，而我平时会经常使用RACSubject用其代替delegate。在刚开始接触RAC的时候，我会觉得RACCommand和RACSubject非常相似，都能够控制执行，都能够进行订阅，然而，它们的区别也是挺大的。
     RACSubject只能单向发送事件，发送者将事件发送出去让接收者接收事件后进行处理，所以，RACSubject可代替代理，被监听者可利用subject发送事件，监听者接收事件然后进行相应的监听处理，不过，事件的传递方向是单向的。
     对于RACCommand，数据流是双向的，某个部件进行某种会产生结果的操作时，利用RACCommand向此部件发送执行事件，部件接收到执行事件后进行相应操作处理并也通过RACCommand将操作结果回调到上层，使得事件得以双向流通。
     */
    /*

     // 一、RACCommand使用步骤:
     // 1.创建命令 initWithSignalBlock:(RACSignal * (^)(id input))signalBlock
     // 2.在signalBlock中，创建RACSignal，并且作为signalBlock的返回值
     // 3.执行命令 - (RACSignal *)execute:(id)input
     
     // 二、RACCommand使用注意:
     // 1.signalBlock必须要返回一个信号，不能传nil.
     // 2.如果不想要传递信号，直接创建空的信号[RACSignal empty];
     // 3.RACCommand中信号如果数据传递完，必须调用[subscriber sendCompleted]，这时命令才会执行完毕，否则永远处于执行中。
     // 4.RACCommand需要被强引用，否则接收不到RACCommand中的信号，因此RACCommand中的信号是延迟发送的。
     
     // 三、RACCommand设计思想：内部signalBlock为什么要返回一个信号，这个信号有什么用。
     // 1.在RAC开发中，通常会把网络请求封装到RACCommand，直接执行某个RACCommand就能发送请求。
     // 2.当RACCommand内部请求到数据的时候，需要把请求的数据传递给外界，这时候就需要通过signalBlock返回的信号传递了。
     
     // 四、如何拿到RACCommand中返回信号发出的数据。
     // 1.RACCommand有个执行信号源executionSignals，这个是signal of signals(信号的信号),意思是信号发出的数据是信号，不是普通的类型。
     // 2.订阅executionSignals就能拿到RACCommand中返回的信号，然后订阅signalBlock返回的信号，就能获取发出的值。
     
     // 五、监听当前命令是否正在执行executing
     
     // 六、使用场景,监听按钮点击，网络请求
     */

}
///MARK switchToLast
-(void)switchToLastDemo{
    //其中switchToLatest表示的是最新发送的信号，验证一下看他是不是最新的信号吧。
    RACSubject *signalOfSignale = [RACSubject subject];
    RACSubject *signal1 = [RACSubject subject];
    RACSubject *signal2 = [RACSubject subject];
    RACSubject *signal3 = [RACSubject subject];
    RACSubject *signal4 = [RACSubject subject];
#pragma mark -- 验证1
    /*
     //订阅信号。signalOfSignale表示信号中的信号，我们订阅到信息肯定信号signal1，我们打印一下
     [signalOfSignale subscribeNext:^(id  _Nullable x) {
     NSLog(@"switchToLatest :%@ signal:%@",x,signal1);
     //signal1订阅获取的是signal2的信息
     [x subscribeNext:^(id  _Nullable x) {
     NSLog(@"switchToLatest signal:%@ sinal：%@",x,signal2);
     [x subscribeNext:^(id  _Nullable x) {
     NSLog(@"switchToLatest %@",x);//所以，我们需要好几步订阅才能拿到最新的消息，这显然太麻烦了。
     }];
     }];
     }];
     
     
     [signalOfSignale sendNext:signal1];
     [signal1 sendNext:signal2];
     [signal2 sendNext:@"come for signal2"];
     */
    
    //我们通过switchToLatest获取到signalOfSignale发送的最新的信号发送信息，我们看看是什么。应该是最新信号signal1发送的消息signal2.
    [signalOfSignale.switchToLatest subscribeNext:^(id  _Nullable x) {
        NSLog(@"now switchToLatest:%@",x);
    }];
    NSLog(@"signal1 :%@ signal2 : %@ signal3 : %@ signal4 : %@",signal1,signal2,signal3,signal4);
    [signalOfSignale sendNext:signal1];
    [signal1 sendNext:signal2];
    //    [signal1 sendNext:@"come for signal1"];
    [signal2 sendNext:signal3];
    [signal3 sendNext:@"come for signal3"];
    
    
#pragma mark -- 验证2
    //在我们开始测试发送多个信号，看拿到是不是最后一个信号
    /*
     [signalOfSignale.switchToLatest subscribeNext:^(id  _Nullable x) {
     NSLog(@"switchToLatest : %@",x);
     }];
     
     
     [signalOfSignale sendNext:signal1];
     [signalOfSignale sendNext:signal2];
     [signalOfSignale sendNext:signal3];
     [signalOfSignale sendNext:signal4];
     
     [signal1 sendNext:@"signal1"];
     [signal2 sendNext:@"signal2"];
     [signal3 sendNext:@"signal3"];
     [signal4 sendNext:@"signal4"];
     */
}
///MARK 数据绑定
-(void)bindData{
    //假设想监听文本框的内容，并且在每次输出结果的时候，都在文本框的内容拼接一段文字“输出：”
    #pragma mark -- 方法1
//    方式一:在返回结果后，拼接。
//    [self.inputOne.rac_textSignal subscribeNext:^(NSString * _Nullable x) {
//        NSLog(@"输出:%@",x);
//    }];
    #pragma mark -- 方法2
    //在返回结果前，拼接，使用RAC中bind方法做处理。
    /*
     bind方法参数:需要传入一个返回值是RACStreamBindBlock的block参数
     RACStreamBindBlock是一个block的类型，返回值是信号，参数（value,stop），因此参数的block返回值也是一个block。

     RACStreamBindBlock:
     参数一(value):表示接收到信号的原始值，还没做处理
     参数二(*stop):用来控制绑定Block，如果*stop = yes,那么就会结束绑定。
     */
    /*
    [[[self.inputOne.rac_textSignal skip:1] bind:^RACSignalBindBlock _Nonnull{
        return ^RACSignal* (id value,BOOL *stop){
            return [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
                [subscriber sendNext:[NSString stringWithFormat:@"输出:%@",value]];
                [subscriber sendCompleted];
                NSString *index = [NSString stringWithFormat:@"%@",value];
                if ([index isEqualToString:@"q"]) {
                    *stop = YES;
                }
                return nil;
            }];
        };
    }] subscribeNext:^(id  _Nullable x) {
        NSLog(@"%@",x);
    }];
     */
    
#pragma mark -- 例子
    RACSubject *subject = [RACSubject subject];
    
    RACSignal *bindedSignal = [subject bind:^RACSignalBindBlock _Nonnull{
        return ^RACSignal * (id value ,BOOL *stop){
            NSLog(@"value:%@",value);
//            return [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
//                [subscriber sendNext:[NSString stringWithFormat:@"%@ 被绑定了",value]];
//                return nil;
//            }];
            //也可以使用RACReturnSignal类，直接把数据返回出去
            return [RACReturnSignal return:[NSString stringWithFormat:@"%@ 被绑定了",value]];
        };
    }];
    
    [bindedSignal subscribeNext:^(id  _Nullable x) {
        NSLog(@"binded info:%@",x);
    }];
    
    [subject sendNext:@"我的消息"];

}
///MARK RAC中的集合类型（RACTuple、RACSequence）
-(void)racDataDemo{
    //主要是为了方便对字典和数组的遍历操作
    //1、RACTuple
    /*
     了解过swift的应该对tuple不陌生。swift中的元组可以放入任何数据类型，包括基本数据类型，OC中的数组只能存储对象。RACTuple就是对OC中的数组进行了一层封装
     */
//    RACTuple *tuple1 = [RACTuple tupleWithObjects:@"dasd",@23,[NSNumber numberWithBool:YES], nil];
//    RACTuple *tuple2 = [RACTuple tupleWithObjectsFromArray:@[@"dhfds"]];
//    RACTuple *tuple3 = [RACTuple tupleWithObjectsFromArray:@[@"dhfds",@"ji2ew"] convertNullsToNils:YES];
//    NSLog(@"tuple first:%@ sencond:%@ thrid:%@",tuple1.first,tuple1[1],tuple1.last);

    //RACSequence
    /*
     还有一个类：RACSequence，这个类可以用来代替我们的NSArray或者NSDictionary，主要就是用来快速遍历，和用来字段转模型。
     */
    
    NSArray *array = @[@"One",@"two",@"three",@8943,@1298];

    NSDictionary *dicInfo = @{@"name":@"shoufuyou",@"address":@"Shanghai"};
    
    RACSequence *sequence = array.rac_sequence;
    RACSignal *signal = sequence.signal;
    [signal subscribeNext:^(id  _Nullable x) {
        NSLog(@"x:%@",x);
    }];
    
    
    RACSequence *dictSeq = dicInfo.rac_sequence;
    RACSignal *dicSignal = dictSeq.signal;
    [dicSignal subscribeNext:^(id  _Nullable x) {
        RACTwoTuple *tuple = x;
        NSLog(@"dict x:%@ info:%@ %@",x,tuple.first,tuple.second);
        //也可以像下面的方式写
        RACTupleUnpack(NSString *key,id value) = x;
        NSLog(@"key:%@ value:%@",key,value);
    }];
    
    //更简洁的方式
    [array.rac_sequence.signal subscribeNext:^(id  _Nullable x) {
        NSLog(@"######info:%@",x);
    }];
    
   RACSequence *seq = [dictSeq map:^id _Nullable(id  _Nullable value) {
        RACTupleUnpack(NSString *key,id valuestr) = value;
        return [NSString stringWithFormat:@"key:%@value:%@",key,valuestr];
    }];
    NSLog(@"mapInfo:%@",[seq array]);
    
}
///MARK 常用的操作rac_leftSeletor、map
-(void)racOperateUse{
    #pragma mark -- rac_leftSeletor
    //1、rac_leftSeletor
    /*
     主要应用的场景就是，一个页面如果有多个请求，然后又要等到数据全部请求到，在刷新的时候，或者类似于这样子的场景就可以使用。像我们之前，某个UI要等几个接口全部数据返回完之后才做某种操作，之前我们通过线程group操作，RAC也可以。
     */
    /*
    RACSignal *signal1 = [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        [subscriber sendNext:@"operation 1"];
        return nil;
    }];
    
    RACSignal *signal2 = [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        [subscriber sendNext:@"operation 2"];
//        [subscriber sendCompleted];
//        [subscriber sendError:nil];
        return nil;
    }];
    
    RACSignal *signal3 = [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        [subscriber sendNext:@"operation 3"];
        return nil;
    }];
    
    [self rac_liftSelector:@selector(updateWith:paramter2:paramter3:) withSignals:signal1,signal2,signal3, nil];//就是说，所有的信号必须调用一次sendNext才会触发操作
     */
    #pragma mark -- map 和 flattenMap
    /*
     Map作用:把源信号的值映射成一个新的值
     Map使用步骤:
         1.传入一个block,类型是返回对象，参数是value
         2.value就是源信号的内容，直接拿到源信号的内容做处理
         3.把处理好的内容，直接返回就好了，不用包装成信号，返回的值，就是映射的值。
     
      flattenMap:平铺地图
         作用:用于信号中信号,把源信号的内容映射成一个新的信号,信号可以是任意类型
      
     flattenMap使用步骤:
          1.传入一个block，block类型是返回值RACStream，参数value
          2.参数value就是源信号的内容，拿到源信号的内容做处理
          3.包装成RACReturnSignal信号，返回出去。
     flattenMap和bind类似
     
     FlatternMap和Map的区别
     * 1.FlatternMap中的Block返回信号。
     * 2.Map中的Block返回对象。
     * 3.开发中，如果信号发出的值不是信号，映射一般使用Map
     * 4.开发中，如果信号发出的值是信号，映射一般使用FlatternMap。
     */
    /*
    RACSignal *sigal = [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        [subscriber sendNext:@"map signal"];
        return nil;
    }];
    
    //绑定信号
    RACSignal *mapedSignal = [sigal map:^id _Nullable(id  _Nullable value) {
//        return value;
        return [NSString stringWithFormat:@"*%@",value];

    }];
    [mapedSignal subscribeNext:^(id  _Nullable x) {
        NSLog(@"%@",x);
    }];
    
    [sigal subscribeNext:^(id  _Nullable x) {
        
    }];*/
    
    #pragma mark -- 发送的不是信号
    RACSubject *subject = [RACSubject subject];
    subject.name = @"subject";
//    RACSignal *mapedSignale = [subject flattenMap:^__kindof RACSignal * _Nullable(id  _Nullable value) {
//        NSLog(@"value:%@",value);//这里是值
//        return [RACReturnSignal return:value];
//    }];
//
//    [mapedSignale subscribeNext:^(id  _Nullable x) {
//        NSLog(@"x：%@",x);
//    }];
//    [subject sendNext:@"flattenMap"];
    #pragma mark -- 发送的信号
    RACSubject *signalOfsignals = [RACSubject subject];
    RACSignal *signalOfMaped = [signalOfsignals flattenMap:^__kindof RACSignal * _Nullable(id  _Nullable value) {
        NSLog(@"value:%@ subject：%@",value,subject);//这里返回的是信号
        return value;
    }];
    [signalOfMaped subscribeNext:^(id  _Nullable x) {
        NSLog(@"x:%@",x);
    }];
    [signalOfsignals sendNext:subject];
    [subject sendNext:@"flattenMap"];
        
    
}
-(void)updateWith:(id)paramter1 paramter2:(id)paramter2 paramter3:(id)paramter3{
    NSLog(@"%@",paramter1);
    NSLog(@"%@",paramter2);
    NSLog(@"%@",paramter3);
    NSLog(@"Complete");
}
///MARK 常用的宏
-(void)definesUse{
    //1、RAC(TARGET, ...)
    /*
     分配一个信号给一个对象的属性，只要有新的信号产生，就会自动分配给特定的key，当信号完成时，绑定自动废弃
     */
    //RAC(self.infoLabel,text) = self.inputOne.rac_textSignal;
    
    //2、RACObserve(TARGET, KEYPATH).当TARGET的KEYPATH发生变化时, 就会产生新的信号.
    [RACObserve(self.infoLabel, text) subscribeNext:^(id  _Nullable x) {
        NSLog(@"info:%@",x);
    }];
    
    //3、RACTuplePack(...)。将指定的值包装成新的元组。至少有一个值
    RACTuple *tuple = RACTuplePack(@"first",@"Tuple");
    NSLog(@"tuple:%@",tuple.first);
    
    //4、RACTupleUnpack(...)。将元组解包为对应的值并赋值给对应的变量
    RACTupleUnpack(id name,id info) = tuple;
    NSLog(@"name:%@ info:%@",name,info);
    
    //5、@weakify(...)和 @strongify(...) 防止循环引用
    
    //6、RACChannelTo 双向绑定
    RACChannelTerminal *two = RACChannelTo(self.inputTwo,text);
    RACChannelTerminal *one = RACChannelTo(self.infoLabel,text);

    [one subscribe:two];
    [two subscribe:one];

    //https://www.cnblogs.com/codetime/p/6226137.html
    @weakify(self);
    [self.inputTwo.rac_textSignal subscribeNext:^(NSString * _Nullable x) {
        @strongify(self);
        self.infoLabel.text = x;
    }];
    
//    自带的一些属性
//    [self.inputOne.rac_newTextChannel subscribe:self.inputTwo.rac_newTextChannel];
//    [self.inputTwo.rac_newTextChannel subscribe:self.inputOne.rac_newTextChannel];
}
@end
