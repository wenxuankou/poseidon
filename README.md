# Poseidon

这是一个用ruby实现的web应用容器，如果你对Unix和网络编程感兴趣，我觉得这是一个很好的参考，puma，unicorn的实现，也是基于类似的网络架构模式，Poseidon一定会给你带来非常多的收获，如果你只是一个web开发者，我相信会给你带来很大的提升

> Poseidon 旨在表达Unix编程和网络架构模式，只对HTTP协议提供了基本的支持，你不应该将其应用到生产环境，虽然它确实很不错，当前已具备良好的性能，不过只是为了让你学习

# Feature

你将从Poseidon中发现这些特性，只有很少的代码，我想你一定会有很多办法改进它

* 可伸缩
* 多进程
* 预分叉
* 非阻塞IO
* Master-Worker的工作方式
* Worker进程异常退出重启
* 匿名管道通信
* 信号量处理
* 支持Rack

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'poseidon', github: 'git@github.com:wenxuankou/poseidon.git', tag: 'v0.1.0'
```

And then execute:

    $ bundle

## Usage

启动服务：

    $ bin/poseidon

查看帮助：

    $ bin/poseidon -h

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Poseidon project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/poseidon/blob/master/CODE_OF_CONDUCT.md).
