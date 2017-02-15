---
title: Vim 学习
date: 2016/7/1 6:46:46
description: Vim 学习
categories: 学习
tags: [vim,linux]
---

### 1. 移动

#### word为单位移动  

~~~
This is a line with example text
 --->-->->----------------->
   w  w  w                3w
~~~

~~~
This is a line with example text
<----<--<-<---------<---
     b     b  b        2b      b
~~~

~~~
This is a line with example text
    <- <--- -----> ---->
     ge ge        e      e
~~~
有一些被认为是non-word的特殊字符, 比如".", "-"或")"充当了word边界的作用。要改变Vim对word边界的定义, 请查看'iskeyword'选项.还可以以空白为分界的WORDs为单位进行移动. 这种WORD与通常意义上的word的边界不同.所以此处用了大写的WORD来区分于word. 它的移动命令也是相应字母的大写形式, 如下所示:
~~~
      ge          b          w                                       e
     <-          <-         --->                                  --->
This is-a line, with special/separated/words (and some more).
     <----<-----            -------------------------->             ----->
        gE     B                                  W                                    E
~~~

#### 移动到行首或者行尾 

~~~
            ^
    <------------
.....This is a line with example text
<----------------- --------------->
            0                        $
~~~

"\$"命令还可接受一个计数, 就象其它的移动命令一样.但是移动到一行的行尾多于一次没有任何意义. 所以它的功能被赋予为移动到下一行的行尾. 如"1\$"会将光标移动到当前行行尾, "2\$"则会移动到下一行的行尾, 如此类推.

####移动到指定字符 

一个最有用的移动命令是单字符搜索命令. 命令"fx"在当前行上查找下一个字符x. 提示: "f"意为"find".例如, 光标位于下行的开头, 假如你要移动到单词human中的字符h上去. 只要执行命令"fh"就可以了,命令"fy"会将光标定位于单词really的尾部.

~~~
To err is human. To really foul up you need a computer.
--------->--------------->
       fh               fy
~~~

该命令可以带一个命令计数; 命令"3fl"会把光标定位于"foul" 的"l"上:

~~~
To err is human. To really foul up you need a computer.
               --------------------->
                            3fl
~~~

F向左搜索

~~~
To err is human. To really foul up you need a computer.
	      <---------------------
                               Fh
~~~

"tx"命令形同"fx"命令, 只不过它不是把光标停留在被搜索字符上, 而是在它之前的一个字符上. 提示: "t"意为"To". 该命令的反方向版是"Tx":

~~~
To err is human. To really foul up you need a computer.
                <------------    ------------->
                          Th                  tn
~~~

这4个命令都可以用";"来重复. 以","也是重复同样的命令, 但是方向与原命令的方向相反 1 . 无论如何, 这4个命令都不会使光标跑到其它行上去. 即使当前的句子还没有结束

####匹配一个括号为目的的移动 

这对方括号[]和花括号{}同样适用

~~~
                  %
             <----->
if (a == (b  *  c) / d)
   <---------------->
               %
~~~

#### 移动到指定行

没有指定命令计数作为参数的话 3 , "G"会把光标定位到最后一行上."gg"命令是跳转到第一行的快捷的方法. "1G"效果也是一样,但是敲起来就没那么顺手了.

~~~
	|    first line of a file     ^
	|    text text text text    |
	|    text text text text    |  gg
  7G  |    text text text text    |
	|    text text text text
	|    text text text text
        V   text text text text    |
	     text text text text    |  G
	     text text text text    |
              last line of a file     V
~~~

另一个移动到某行的方法是在命令"%"之前指定一个命令计数 1 . 比如"50%"将会把光标定位在文件的中间 2 . "90%"跳到接近文件尾的地方 3 .

上面的这些命令都假设你只是想跳转到文件中的某一行上, 不管该行当前是否显示在屏幕上.但如果你只是想移动到目前显示在屏幕上的那些行呢? 下图展示了达到这一目标的几个命令:"H"意为Home, "M"为Middle, "L"为Last.

~~~
		+---------------------------+
H -->        |  text sample text              |
		|  sample text		        |
		|  text sample text              |
  		  |  sample text                     |
M -->       |  text sample text              |
		|  sample text 		         |
		|  text sample text	            |
		|  sample text		        |
L -->         |  text sample text              |
		+---------------------------+
~~~

Vim允许你在文本中定义你自己的标记. 命令"ma"将当前光标下的位置名之为标记"a".从a到z一共可以使用26个自定义的标记. 定义后的标记在屏幕上也看不出来. 不过Vim在内部记录了它们所代表的位置.

要跳转到一个你定义过的标记, 使用命令`{mark}, {mark}就是你定义的标记的名字.就象这样:

~~~
`a
~~~

命令'mark(单引号, 或者叫呼应单引号)会使你跳转到mark所在行的行首.这与\`mark略有不同, `mark会精准地把你带到你定义mark时所在的行和列.

你可以移动到文件开始处并在此放置一个名为s(start)的标记:

~~~
ms
~~~
#### 修改历史光标跳转

~~~
Ctrl-O  前一个修改所在光标位置 
Ctrl-I   后一个修改所在光标位置
~~~

#### 滚动 ####
- CTRL-U命令会使文本向下滚动半屏. 也可以想象为在显示文本的窗
口向上滚动了半屏. 不要担心这种容易混淆的解释, 不是只有你一个人
搞不清楚.
- CTRL-D命令将窗口向下移动半屏, 所以相当于文本向上滚动了半屏:
- "zz"命令 会把当前行置为屏幕正中央
- "zt"命令会把当前行置于屏幕顶端  
- "zb"则把当前行置于屏幕底端 
- 一次滚动一行可以使用CTRL-E(向上滚动)和CTRL-Y(向下滚动)


----------

### 2. 删除
#### 操作符命令和位移 

"4w"命令是向前移动4个word. 所以"d4w"命令是删除4个word.

~~~
To err is human. To really foul up you need a computer.
                            ------------------>
                                    d4w
To err is human. you need a computer.
~~~
Vim只删除到位移命令之后光标的前一个位置. 这是因为Vim知道你并不是要删除下一个word的第一个字符. 如果你用"e"命令来移动到word的末尾, Vim也会假设你是要包括那最后一个字符 
~~~
To err is human. you need a computer.
                           -------->
                               d2e
To err is human. a computer.
~~~

删除到行尾

~~~
To err is human. a computer.
                           ------------>
                               d$
To err is human
~~~

删除换行符
~~~
命令J
~~~

#### 改变文本 

~~~
To err is human
     ------->
      c2wbe<Esc>
To be human
~~~

快捷命令

~~~
x      代表dl(删除当前光标下的字符)
X 	代表dh(删除当前光标左边的字符)
D     代表d$(删除到行尾的内容)
C 	代表c$(修改到行尾的内容)
s 	代表cl(修改一个字符)
S 	代表cc(修改一整行)
~~~

#### 替换 

单个替换

~~~
there is somerhing grong here
rT                  rt       rw
There is something wrong here
~~~

#### 重复改动 

"."命令是Vim中一个简单而强大的命令. 它会重复上一次做出的改动. 例如, 假设你在编辑一个HTML文件, 想删除其中所有的\<B\>标签. 你把光标置于\<B\>的<字符上然后命令"df>". 然后到\</B\>的<上用"."命令做同样的事. "."命令会执行上一次所执行的更改命令( 此例中是"df>").要删除另一个标签, 同样把光标置于<字符上然后执行"."命令即可.

~~~
                                       To <B>generate</B> a table of <B>contents
f<           找到第一个 <     --->
df>         删除到 >处的内容   -->
f<           找到下一个 <                  --------->
.              重复 df>                                      --->
f<           找到下一个 <                                    ------------->
.              重复 df>                                                                -->
~~~

把"four"改为"five". 它在你的文件里多次出现. 你可以用以下命令来做出修改:

~~~
/four<Enter>     找到第一个字符串"four"
cwfive<Esc>      把它改为"five"
n 	  		    找到下一个字符串"four"
. 			   同样改为"five"
n 		          继续找下一个
. 			   做同样的修改
			等等
~~~

如果光标位于一个单词的中间而你要删除这个单词, 通常你需要把光标移到该单词的开头然后用"dw"命令. 不过有一个更简单的办法:"daw"，同时也删除掉单词后的空格，若不打算删除单词后的空格，使用:"diw"

~~~
this is some example text.
		    daw
this is some text.
~~~

删除

~~~
x       删除当前光标下的字符("dl"的快捷命令)
X       删除当前光标之前的字符("dh"的快捷命令)
D      删除自当前光标至行尾的内容("d$"的快捷命令)
dw    删除自当前光标至下一个word的开头
db     删除自当前光标至前一个word的开始
diw    删除当前光标所在的word(不包括空白字符)
daw   删除当前光标所在的word(包括空白字符)
dG     删除当前行至文件尾的内容
dgg   删除当前行至文件头的内容
~~~

~~~
~      改变当前光标下字符的大小写, 并将光标移至下一个字符. 这不是一个操作符命令(除非你设置了'tildeop'3 选项), 所以你不能让它与一个位移命令搭配使用. 但它可以在Visual模式下改变所有被选中的文本的大小写.
I       将光标置于当前行第一个非空白字符处并进入Insert模式
A     当光标置于当前行尾并进入Insert模式
~~~
