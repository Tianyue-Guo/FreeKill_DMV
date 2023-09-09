# 新月杀（FreeKill） 

___

## 原README文件在如下链接中。
https://github.com/Qsgs-Fans/FreeKill
许可证仍列在下一标题之下。

## 许可证

本仓库使用GPLv3作为许可证。详见`LICENSE`文件。

## 如何加入新武将？

持续更新中。

## 如何联机？

# 大致原理： 内网穿透

我们使用了两种实现内网穿透的工具： FRP（Fast Reverse Proxy，https://github.com/fatedier/frp）和ZeroTier（https://www.zerotier.com/）。

1. FRP 开源工具可以将本地服务器的IP暴露在一个公网IP之下。我们使用了AWS Lightsail搭建了一个ubuntu服务器，
从而建立起公网IP。因此，局域网外的其他用户便可以通过接入此公网IP从而加入局域网内的游戏服务器。
此处参考了如下教程：
https://blog.csdn.net/starvapour/article/details/122384004
https://www.bilibili.com/read/cv11743272/
https://cloud.tencent.com/developer/news/247131
2. ZeroTier可以组建一个虚拟局域网，从而使得加入的用户都在虚拟局域网之下并互相访问。



# FRP 使用方法

0. 云服务器IPv4： 3.237.189.14. 本地OS： Windows。 确保云服务器上的FRPS和某本地机器FRPC正常运行即可。
1. 下载此repo到本地，可以git clone、下载zip等。
2. 找到FreeKill.exe 并双击。
3. 进入游戏界面之后，点击单机游玩，再退出并返回主界面。
4. 点击加入服务器。进入服务器界面之后点击添加服务器。
5. 输入如上IPv4地址。用户名与密码自行设置。
6. 加入服务器，就可进入游戏大厅。可以开玩了！


# ZeroTier使用方法

0. 下载并安装zerotier（https://www.zerotier.com/）。右下角找到图标并点击“Join New Network”并输入16位Network ID。
1. 找ZeroTier管理者要IPv4地址。
2. 其余步骤与上述1-6相同。




