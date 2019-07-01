---
layout: post
title:  在EC2上部署Nginx的静态网站
date:   2019-06-20 13:25:35 +0200
categories: translation
---

本文将介绍如何设置一个简单的静态网站并将其部署在EC2 Nginx上。

> [英文原文][registering-a-domain-and-routing-traffic-to-the-website](https://romainstrock.com/blog/static-website-nginx-ec2.html#3-registering-a-domain-and-routing-traffic-to-the-website)

所有示例都来自我构建此网站的经验，从创建静态文件和设置服务器到注册域名和启用HTTPS。

## 创建静态文件

出于此示例的目的，我们将使用[Jekyll](https://jekyllrb.com/)生成和管理静态文件。

Jekyll是一个静态网站生成器。 它可以帮助您分别在html和Markdown文件中分离布局和
内容，并将所有内容编译为可随时部署到网站的文件。

该项目的[`README`](https://github.com/jekyll/jekyll/blob/master/README.markdown#philosophy)阐述了这一理念：

> Jekyll does what you tell it to do — no more, no less.
>
> It doesn’t try to outsmart users by making bold assumptions, nor does
> it burden them with needless complexity and configuration.
>
> Put simply, Jekyll gets out of your way and allows you to concentrate
> on what truly matters: your content.


一种流行的替代方案是[Hugo]（https://gohugo.io/）。但我决定选择Jekyll，
因为我熟悉模板，而且碰巧喜欢它默认的主题。 Jekyll和Hugo都有大量的免费和
开源主题，所以请随意选择不同的主题。

### 安装Jekyll & 配置项目 

首先，让我们确保安装了最新版本的ruby：

    $> ruby -v
    ruby 2.5.0p0 (2017-12-25 revision 61468) [x86_64-darwin16]

Ruby \>= 2.2.5 is required for Jekyll.

更新ruby，请安装rvm，ruby的包管理器：

    $> curl -L https://get.rvm.io | bash -s stable
    $> rvm install ruby-2.5.0
    $> rvm --default use 2.5.0

我们现在可以安装Jekyll以及bundler来帮助构建和运行开发服务器：

    $> gem install jekyll bundler

设置目录结构：

    $> jekyll new romainstrock.com
    $> cd romainstrock.com
    $> bundle exec jekyll serve
    Development server listening on http://localhost:4000

#### 浏览 [http://localhost:4000](http://localhost:4000/)

网站布局已设置。 我们将很快添加内容，但首先让我们看看如何将主题布局导
入到项目中。这样可以轻松编辑布局文件以符合我们的目的。

默认的，这个主题是“隐藏”在[ruby gem](https://en.wikipedia.org/wiki/RubyGems)里面的。

让我们找出这个隐藏主题的位置：

    $> bundle show minima  # minima is the default theme
    /usr/local/lib/ruby/gems/2.5.0/gems/minima-2.1.0

复制文件：

    $> cp -r /usr/local/lib/ruby/gems/2.5.0/gems/minima-2.1.0/* .

Finally, we need to adjust the project settings, as described in the
最后，我们需要调整项目的配置，根据[官方文档](https://jekyllrb.com/docs/themes/#converting-gem-based-themes-to-regular-themes):：

-   Open `Gemfile` and remove
    `gem "minima", "~> 2.0"`
-   Open `_config.yml`and remove
    `theme: minima`

You may want to tweak the project metadata further by editing
`_config.yml`, e.g website title, author,
description, etc.
您可能希望通过编辑`_config.yml`进一步调整项目元数据，例如网站标题，作者，描述等。

### 创建一个主页

打开`index.md`并配置主页的元数据：

    ---
    layout: home
    title: Romain Strock
    description: Personal webpage & blog
    ---

重要的是布局。 它描述了用于呈现页面的html文件的名称。

`_layouts/home.html`像以下这样:

    ---
    layout: default
    ---

    <div class="home">
        {{ content }}
    </div>

这个`content` 变量是来自以下`index.md`头部，例如：

    ---
    layout: home
    title: Romain Strock
    description: Personal webpage & blog
    ---

    This text will be available via the content variable.

再次运行服务器，继续，服务器将会自动更新，当有文件修改的时候。

    $> bundle exec jekyll serve

修改布局的任务留给读者练习。 花点时间调整模板以符合您的期望。

#### 演示: [romainstrock.com](https://romainstrock.com/) 

接下来，让我们创建blog。

### 设置blog

出于此示例的目的，博客是：

-   引入博客并列出现有帖子的索引页面，
-   一系列帖子。

有了Jekyll，创建帖子有两种主要方式。 一种方法是将帖子添加到_posts目录。 
这是定义帖子的常用方法，但主要缺点是帖子名称需要遵循以下严格约定：

`YEAR-MONTH-DAY-title.md`

在构建时，帖子扩展为`_site/posts/<YEAR>/<MONTH>/<DAY>/<title>.html`。
这很不幸，因为它迫使我们在网址中包含日期。

使用Jekyll服务器（如我们的开发服务器）时，可以通过在后元数据中设置
`permalink: <title>.html`来克服此限制。但是，
在这个例子中，我们依赖于输出html结构，因为我们的Web服务器只提供静态文件 - 而不运行Jekyll。

构建博客的更好方法是使用[collections](https://jekyllrb.com/docs/collections/).

在`_config.yaml`:为项目添加一个新collection：

    collections:
      blog:
        output: true

然后创建一个文件夹`_blog`，它将保存博客索引和帖子。

博客索引是在请求“naked”`/blog/`url时呈现的页面。

创建文件`_blog/index.md`:

    ---
    layout: blog
    title: Machine learning, AI and tech
    description: Blogging about Machine learning, AI and tech.
    permalink: /blog/
    ---

现在的关键是创建一个新的布局文件`_layouts/blog.html`,通过内容列出所有的帖子。

    ---
    layout: default
    ---

    <div class="home">
      {% if page.title %}
        <h1 class="page-heading">{{ page.title }}</h1>
      {% endif %}

      {{ content }}

      <!-- Loop over the existing posts -->
      {% if site.blog.size > 1 %}
        <h2 class="post-list-heading">{{ page.list_title | default: "Posts" }}</h2>
        <ul class="post-list">
          {% for post in site.blog %}
          {% if post.url != '/blog/' %}
          <li>
            {% assign date_format = site.minima.date_format | default: "%b %-d, %Y" %}
            <span class="post-meta">{{ post.date | date: date_format }}</span>
            <h3>
              <a class="post-link" href="{{ post.url | relative_url }}">
                {{ post.title | escape }}
              </a>
            </h3>
            {% if site.show_excerpts %}
              {{ post.excerpt }}
            {% endif %}
          </li>
          {% endif %}
          {% endfor %}
        </ul>

        <!-- Optional RSS feed -->
        <p class="rss-subscribe">Subscribe <a href="/feed.xml">via RSS</a></p>
      {% endif %}
    </div>

#### 演示: [/blog/](https://romainstrock.com/blog/)

我们现在创建一个帖子。

创建一个名为`_blog/<post-url>.md`的新文件，例如`_blog/static-website-nginx-ec2.md`

    ---
    layout: post
    title:  "Static website hosting with nginx on EC2"
    description: How to host a simple website & blog with nginx on EC2
    date: 2018-02-10
    ---

    Let's find out.

默认布局`_layouts/page.html`非常好，但可以随意修改它。

#### 演示: *当前发布*

现在网站已准备就绪，让我们看看如何将其部署到EC2实例。

* * * * *

## 设置服务器

在本章节中，我们将演示如何运行EC2实例，以及如何ubuntu上配置nginx服务器。

### 配置EC2实例

本节假定您已拥有AWS账户以及启动新实例所需的权限。

我不会详细介绍启动EC2实例的细节，但以下是关键点：

-   最新的Ubuntu AMI
-   实例类型：t2.nano，EC2上最便宜的机器（512 Mib ram，1个虚拟CPU），每月不到5美元。
-   创建安全组。 更多细节如下
-   （可选）您可以将IAM角色附加到此计算机以赋予其一些权限，例如，无需指定凭据即可访问S3。
-   *重要提示*: 创建新的SSH秘钥对,或者使用已经存在的秘钥 *如果你能访问这秘钥的话*。
	
安全策略组很重要，它基本上配置实例上防火墙的白名单的一种方式，例如，向外界开放的端口。

这是我推荐的一种安全组的配置方式：

![安全组](/assets/images/security-group.png)

我们的想法是打开端口80和443以分别允许传入HTTP和HTTPS流量，以及用于SSH访问的端口22。
请注意，端口22仅对单个IP开放，因此只有您可以访问它。 缺点是如果使用动态IP，则必须经常重新访问此设置。

我不太清楚为什么界面显示端口80和443的2个条目。每个端口只需要一个条目，
值为`0.0.0.0/0`。

如果您搞砸了其中一个步骤，请不要担心，您所要做的就是终止实例并重新开始。

启动实例并等待它完成初始化。

接下来，我们需要为此计算机分配持久IP。 为此，我们将使用亚马逊所谓的弹性IP。

它们很容易从EC2仪表板中分配，因此请继续操作。 然后将其分配给新创建的实例。

使用弹性IP而不是使用实例原始公共IP的优点是前者是静态的，如果要终止此实例，
可以很容易地将其重新分配给另一个实例（由您或亚马逊决定将其终止，因为这时有发生。）
这样，我们可以安全地将DNS A记录附加到此IP以将流量路由到实例，
而不必担心如果实例终止则必须随之更改它。 我们将在第3部分详细讨论它。

现在我们的实例已启动并运行，让我们进入并开始配置它。

您将需要通过ssh实例的私钥和实例IP方式连接：

    $> ssh -i <instance-ssh-private-key> ubuntu@<IP>

当提示是否要继续时，请输入“Yes”。

在实例上，我们需要安装nginx以及一些更多的软件包来处理S3，我们将使用它来存储网站代码：

    ubuntu@ip $> sudo apt-get update  # let's make sure we know about recent package versions
    ubuntu@ip $> sudo apt-get install nginx  # Install nginx
    ubuntu@ip $> sudo apt-get install python-pip python-dev build-essential  # Install python & pip
    ubuntu@ip $> sudo pip install --upgrade pip  # update python's package manager
    ubuntu@ip $> pip install awscli --upgrade --user  # Install AWS command line tool

现在已配置实例。 剩下的就是将网站的代码部署到服务器并配置nginx来访问文件。

### 部署代码到服务器

部署代码的最简单方法是将文件通过ssh复制到服务器，例如：

    $> scp -i <instance-ssh-private-key> -rp _site/ ubuntu@<IP>:/home/ubuntu


对于不需要经常更新的网站，这是一个很好的解决方案。 但是我决定使用S3进行处理，
因为它更简洁，并且可以让以后自动化交付过程变得容易。

首先，让我们将代码上传到Amazon S3。 在实例，我们需要确保安装了python和pip。
在Ubuntu上，上面的步骤将起作用。 在Mac上，您可能希望使用[brew](https://brew.sh/)或类似方法安装它。

Ubuntu:

    $> sudo apt-get update
    $> sudo apt-get install python-pip python-dev build-essential
    $> pip install awscli --upgrade --user

Mac:

    $> brew install python3
    $> pip3 install awscli --upgrade --user

然后让我们继续创建 `deploy.sh`:

    #!/bin/bash

    # Build the website for production
    JEKYLL_ENV=production bundle exec jekyll build

    # Sync all the built files to a bucket on S3.
    pushd _site
    aws s3 sync --exact-timestamps --delete . s3://<your-bucket>/
    popd

*注意:* 你可能需要配置 aws cli，通过配置aws的凭证，然后执行`aws configure`

更改脚本权限并运行 `deploy.sh`:

    $> chmod 775 deploy.sh
    $> ./deploy.sh

现在所有文件都应该在桶中了。

接下来，让我们再次SSH到实例中并从存储桶中取出代码：

    ubuntu@ip $> mkdir <website-name>
    ubuntu@ip $> aws s3 sync --exact-timestamps --delete s3://<your-bucket>/ <website-name>/

*注意:* 如果您没有为此实例设置IAM角色，则需要通过运行`aws configure`来配置aws cli。

现在，每次要更新代码时，您所要做的就是重新运行`deploy.sh`，然后SSH进入实例并同步文件。

这种方法的一个潜在优势是，当S3上的内容发生变化时，很容易修改自动化同步文件的部署过程。
例如，在编译代码后，我们可以创建一个checksum 文件并将其更其他内容一起上传到S3上。

`deploy.sh`:

    #!/bin/bash

    # Build the website for production
    JEKYLL_ENV=production bundle exec jekyll build

    # Add checksum file
    # Note: on linux, replace md5 with md5sum
    tar c . | md5 > CHECKSUM

    # Sync all the built files to a bucket on S3.
    pushd _site
    aws s3 sync --exact-timestamps --delete . s3://<your-bucket>/
    popd

然后在实例上创建一个简单的cron job，检查校验和文件是否已更改。
如果是，请再次运行sync命令。 cron job的实现再次留给读者练习。

现在我们已经知道了怎么将代码部署到服务器，接下来，让我们来看看如何配置Nginx以提供文件服务。

### 配置nginx

首先，让我们列出需求：


-   在服务端，目录`<website-name>/`是网站的根目录，
    所有的links都是从这里获取，我们必须让nginx知道它。
-   我们希望能够接受来自端口80传入的HTTP流量（我们将在最后一节中看到如何
    扩展配置以支持端口443上的HTTPS）	
-   我们希望`http://<domain>/`提供index.html
-   我们希望`http://<domain>/blog/`提供博客页面
-   我们希望`http://<domain>/blog/<post-title>.html`提供帖子页面。
-   我们希望能够提供正确的content-type.
-   除此以外的其他内容则返回HTTP error 404 Not Found

`nginx.conf`:

    worker_processes  1;  # The instance is small, 1 process is enough.

    error_log  /var/log/nginx/error.log info;  # Error log, level info or greater
    pid        /var/run/nginx.pid;  # nginx process ID

    events {
      worker_connections  1024;  # Max number of simultaneous connections.
    }

    http {
      # Access log: requests hitting your website.
      access_log         /var/log/nginx/access.log;

      # Let nginx infer content types automatically.
      include            /etc/nginx/mime.types;

      # "sendfile allows to transfer data from a file descriptor to another directly in kernel space.
      # sendfile allows to save lots of resources [when serving static files]"
      # Quoting https://thoughts.t37.net/nginx-optimization-understanding-sendfile-tcp-nodelay-and-tcp-nopush-c55cdd276765#8e26
      sendfile           on;

      # Keep connection alive for no more than one minute
      keepalive_timeout  60s;

      # Automatically gzip the output, except for IE 6 clients (hopefully rare)
      gzip on;
      gzip_disable "msie6";

      # Set website's root
      root /home/ubuntu/<website-name>;

      # Create a web server
      server {
        listen 80;  # Listen on HTTP port 80

        # Cache assets for 5 minutes.
        add_header Cache-Control max-age=300;

        # Configure 404 page.
        error_page 404 /404.html;

        # Route / to index.html.
        location = / {
          try_files /index.html =404;
        }

        # Route Blog index url.
        location = /blog/ {
          try_files /blog/index.html =404;
        }

        # For everything else, try to find a file matching the path or return a 404.
        location / {
            try_files $uri =404;
        }
      }
    }

剩下的就是将此文件上传到服务器，例如通过scp ：

    $> scp -i <private-key> nginx.conf ubuntu@<IP>

然后SSH到服务器，将配置文件复制到正确的位置并重新启动nginx。

    ubuntu@ip $> sudo cp nginx.conf /etc/nginx/
    ubuntu@ip $> sudo service nginx restart

如果配置出现问题，您可以通过运行以下命令来调试它：

    ubuntu@ip $> systemctl status nginx.service
     nginx.service - A high performance web server and a reverse proxy server
       Loaded: loaded (/lib/systemd/system/nginx.service; enabled; vendor preset: enabled)
       Active: **active (running)** since Sun 2018-02-11 02:16:06 UTC; 17h ago
     Main PID: 21982 (nginx)
     ...

如果此命令显示服务正在运行，我们现在可以测试它了。

#### 浏览`http://<IP>/`

你将可以一睹你网站的芳容。

* * * * *

## 注册域名并将流量路由到网站 


现在我们网站正在提供服务，我们需要为它购买域名并将流量引导到服务器。 这是一个简短的部分，我将主要介绍各种有用的资源。

我个人喜欢使用[Gandi](https://www.gandi.net/en)。 但是还有十几个其他注册商可用。

购买域名后，我们需要让DNS服务器知道在哪里找到我们的服务器。 这是通过添加DNS条目[`A record`](https://en.wikipedia.org/wiki/List_of_DNS_record_types)来完成.

如何设置DNS记录取决于您的注册商。 Gandi的文档就在[这里](https://wiki.gandi.net/en/dns/zone/a-record).

您需要输入以下内容：

-   `A`类型：`A`
-   名称： *适用于一级域名（ http://romainstrock.com ）或输入子域名，例如www
-   值：服务器的IP
-   TTL（生存时间）：3小时左右（即无需每3小时重新验证一次）

等几分钟，您应该可以通过域名访问服务器。 如果域曾经有一条A记录指向其他地方，则可能需要更长时间（最多48小时）

我们已经成功设置了一个可通过域名访问的HTTP服务器，并提供静态页面访问。

最后但同样重要的是，我们需要设置HTTPS以允许与我们网站的安全连接。

* * * * *

## 设置HTTPS

为网站设置HTTPS曾经是一种痛苦，部分原因是证书过去只是商业化，而且因为正确设置它并不总是很简单

如今，借助[Let’s Encrypt](https://letsencrypt.org/),可以获得免费证书，
这可以通过自动化流程来降低颁发机构运行证书的成本。所以让我们继续使用Let's Encrypt创建一个证书。

文档在[这里](https://letsencrypt.org/getting-started/) 。在本指南中，他们建议使用certbot，从命令行就可以轻松生成证书。

我们先在服务器上安装certbot :

    ubuntu@ip $> sudo apt-get install software-properties-common
    ubuntu@ip $> sudo add-apt-repository ppa:certbot/certbot
    ubuntu@ip $> sudo apt-get update
    ubuntu@ip $> sudo apt-get install certbot

然后运行以下命令并按照说明操作：

    ubuntu@ip $> sudo certbot certonly

当提示输入域名时，请输入已注册的域名`<domain>`和`www.<domain>`.

在该过程结束时，应该会生成两个文件`<domain>.key`和`<domain>.pem`.

*这些文件很重要，应保存在安全的地方。*

最后，让我们看看如何通过这些秘钥修改nginx配置以接受HTTPS连接。

`nginx.conf`:

    worker_processes  1;

    # ... unchanged

    http {
      # ... unchanged

      # Modify the web server to listen on port 443 instead of 80 and enable SSL.
      server {
        listen 443 ssl;  # Listen on HTTPS port 443

        server_name <domain> www.<domain>;  # Specify allowed domain names

        ssl on;  # Enable SSL
        ssl_certificate /home/ubuntu/<domain>.pem;  # Path to the certificate .pem file
        ssl_certificate_key /home/ubuntu/<domain>.key;  # Path to the certificate .key file

        # ... unchanged
      }

      # Add a new server listening on HTTP port 80 and redirects all the traffic to https://*
      server {
        listen 80;
        return 301 https://$server_name$request_uri;  # Permanent redirection to the HTTPS version
      }
    }

重启nginx：

    ubuntu@ip $> sudo service nginx restart

您的网站现在应该在网址栏前面展示一个非常令人满意的🔒

![HTTPS lock](/assets/images/https-lock.png)

* * * * *

## 总结

在本文中，我们了解到

-   如何使用Jekyll创建一个简单的静态网站和博客
-   如何将此网站部署到EC2实例
-   如何设置nginx来提供静态网页访问
-   如何注册域名并将流量路由到网站
-   如何设置HTTPS

如果你已经做到这一点，干得好！

我们只是触及了我们使用的大多数工具的基础功能，但它足以构建一个简单的网站。 
大多数概念都可以扩展和改进，正如我们在第2节中通过服务器自动更新文件所看到的那样

本网站的源代码可在[Github](https://github.com/srom/romainstrock.com).上找到

如果您对本文有任何疑问或意见，请随时给我发电子邮件。

[](https://romainstrock.com/blog/static-website-nginx-ec2.html)

-   Romain Strock
-   [romain.strock@gmail.com](mailto:romain.strock@gmail.com)

…

-   [](https://github.com/srom)
    srom
-   [](https://www.linkedin.com/in/romain-strock)
    romain-strock
-   [](https://www.twitter.com/romainstrock)
    romainstrock
