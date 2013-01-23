#**Lab 22: Creating a PHP application (Estimated time: 30 minutes)**

**Server used:**

* localhost
* node host

**Tools used:**

* rhc

In this lab, we are ready to start using OpenShift Enterprise to create our first application.  To create an application, we will be using the *rhc app* command.  In order to view all of the command available for the *rhc app* command, enter the following command:

	$ rhc app -h
	
This will provide you with the following output:

	List of Actions
 	create             Create an application and adds it to a domain
  	git-clone          Clone and configure an application's repository locally
  	delete             Delete an application from the server
  	start              Start the application
  	stop               Stop the application
  	force-stop         Stops all application processes
  	restart            Restart the application
  	reload             Reload the application's configuration
  	tidy               Clean out the application's logs and tmp directories and tidy up the git repo on the server
  	show               Show information about an application
  	status             Show status of an application's gears

	Global Options
  	-l, --rhlogin login       OpenShift login
  	-p, --password password   OpenShift password
  	-d, --debug               Turn on debugging
  	--timeout seconds         Set the timeout in seconds for network commands
  	--noprompt                Suppress the interactive setup wizard from running before a command
  	--config FILE             Path of a different config file
  	-h, --help                Display help documentation
  	-v, --version             Display version information


##**Create new application**

It is very easy to create an OpenShift Enterprise application using rhc. The command to create an application is *rhc app create* and it requires two mandatory arguments:

* **Application Name (-a or --app)** : The name of the application. Name can only contain alpha-numeric characters and at max contain only 32 characters.

* **Type (-t or --type)**: The type is used to specify which runtime to use.  

Create a directory to hold your OpenShift Enterprise code projects:

	$ cd ~
	$ mkdir ose
	$ cd ose
	
To create an application that uses the *php* runtime, issue the following command:

	$ rhc app create -a firstphp -t php
	
After entering that command, you should see the following output:


	Password: ****
	
	Creating application 'firstphp'
	===============================
	
	  Namespace: ose
	  Scaling:   no
	  Cartridge: php
	  Gear Size: default
	
	Your application's domain name is being propagated worldwide (this might take a minute)...
	The authenticity of host 'firstphp-ose.example.com (10.4.59.221)' can't be established.
	RSA key fingerprint is 6c:a5:e5:fa:75:db:5a:7f:dc:a2:44:ed:e4:97:af:3c.
	Are you sure you want to continue connecting (yes/no)? yes
	Cloning into 'firstphp'...
	done
	
	firstphp @ http://firstphp-ose.example.com/
	===========================================
	  Application Info
	  ================
	    Git URL   = ssh://e9e92282a16b49e7b78d69822ac53e1d@firstphp-ose.example.com/~/git/firstphp.git/
	    UUID      = e9e92282a16b49e7b78d69822ac53e1d
	    Created   = 1:47 PM
	    Gear Size = small
	    SSH URL   = ssh://e9e92282a16b49e7b78d69822ac53e1d@firstphp-ose.example.com
	  Cartridges
	  ==========
	    php-5.3
	
	RESULT:
	Application firstphp was created.
	


If you completed all of the steps in lab 16 correctly, you should be able to verify that your application was created correctly by opening up a web browser and entering the following URL:

	http://firstphp-ose.example.com
	
You should see the default template that OpenShift Enterprise uses for a new application.

![](http://training.runcloudrun.com/images/firstphp.png)

##**What just happened?**

After you entered the command to create a new PHP application a lot of things happened under the covers:

* A request was made to the broker application host to create a new php application
* A message was dropped using MCollective and ActiveMQ to find a node to handle the application creation request
* The node host responded to the request and created an application / gear for you
* All SELinux and cgroup policies were enabled for your application gear
* A userid was created for your application gear
* A private git repository was created for you on the node host
* The git repository was cloned on your local machine
* BIND was updated on the broker host to include an entry for your application

##**Understanding directory structure on node host**
	
It is important to understand the directory structure of each OpenShift Enterprise application gear.  For the PHP application that we just created, we can verify and examine the layout of the gear on the node host.  SSH to your node host and execute the following commands:

	# cd /var/lib/openshift
	# ls
	
You will see output similar to the following:

	e9e92282a16b49e7b78d69822ac53e1d
	
The above is the unique user id that was created for the newly created php gear.  Lets examine the contents of this gear by using the following command:

	# cd e9e92282a16b49e7b78d69822ac53e1d
	# ls -al
	
You should see the following directories:

	total 44
	drwxr-x---.  9 root e9e92282a16b49e7b78d69822ac53e1d 4096 Jan 21 13:47 .
	drwxr-xr-x.  5 root root                             4096 Jan 21 13:47 ..
	drwxr-xr-x.  4 root e9e92282a16b49e7b78d69822ac53e1d 4096 Jan 21 13:47 app-root
	drwxr-x---.  3 root e9e92282a16b49e7b78d69822ac53e1d 4096 Jan 21 13:47 .env
	drwxr-xr-x.  3 root root                             4096 Jan 21 13:47 git
	-rw-r--r--.  1 root root                               56 Jan 21 13:47 .gitconfig
	-rw-r--r--.  1 root root                             1352 Jan 21 13:47 .pearrc
	drwxr-xr-x. 10 root root                             4096 Jan 21 13:47 php-5.3
	d---------.  3 root root                             4096 Jan 21 13:47 .sandbox
	drwxr-x---.  2 root e9e92282a16b49e7b78d69822ac53e1d 4096 Jan 21 13:47 .ssh
	d---------.  3 root root                             4096 Jan 21 13:47 .tmp
	[root@node e9e92282a16b49e7b78d69822ac53e1d]# 


During a previous lab, when we setup the *rhc* tools, our SSH key was uploaded to the server to enable us to authenticate to the system without having to provide a password.  The key we provided was actually appended to the *authorized_key* file.  To verify this, use the following command to view the contents of the file:

	# cat .ssh/authorized_keys
	
You will also notice the following three directories:

* app-root - Contains your core application code and your data directory to store persistent data.
* git - Your private git repository that was created upon application creation.
* php-5.3 - The core php runtime and associated configuration files.  Your application is served from this directory.

##**Understanding directory structure on localhost**

When you created the PHP application using the *rhc app create* command, the private git repository that was created on your node host was cloned to your local machine.

	$ cd firstphp
	$ ls -al
	
You should see the following information:


	total 8
	drwxr-xr-x   9 gshipley  staff   306 Jan 21 13:48 .
	drwxr-xr-x   3 gshipley  staff   102 Jan 21 13:48 ..
	drwxr-xr-x  13 gshipley  staff   442 Jan 21 13:48 .git
	drwxr-xr-x   5 gshipley  staff   170 Jan 21 13:48 .openshift
	-rw-r--r--   1 gshipley  staff  2715 Jan 21 13:48 README
	-rw-r--r--   1 gshipley  staff     0 Jan 21 13:48 deplist.txt
	drwxr-xr-x   3 gshipley  staff   102 Jan 21 13:48 libs
	drwxr-xr-x   3 gshipley  staff   102 Jan 21 13:48 misc
	drwxr-xr-x   4 gshipley  staff   136 Jan 21 13:48 php


###**.git directory**

If you are not familiar with the git revision control system, this is the location all information about the git repositories that you will be interacting with.  For instance, to list all of the repositories that you are currently setup to use for this project, issue the following command:

	$ cat .git/config
	
You should see the following information which specifies the URL for our repository that is hosted on the OpenShift Enterprise node host:

	[core]
		repositoryformatversion = 0
		filemode = true
		bare = false
		logallrefupdates = true
		ignorecase = true
	[remote "origin"]
		fetch = +refs/heads/*:refs/remotes/origin/*
		url = ssh://e9e92282a16b49e7b78d69822ac53e1d@firstphp-ose.example.com/~/git/firstphp.git/
	[branch "master"]
		remote = origin
		merge = refs/heads/master
	[rhc]
		app-uuid = e9e92282a16b49e7b78d69822ac53e1d


**Note:** You are also able to add other remote repositories.  This is useful for developers who also use github or have private git repositories for an existing code base.

###**.openshift directory**

The .openshift directory is a hidden directory where a user can create action hooks, set markers, and create cron jobs.  

Action hooks are scripts that are executed directly so that can be written in python, php, ruby, shell, etc.  OpenShift Enterprise supports the following action hooks:

| Action Hook | Description|
| :---------------  | :------------ |
| build | Executed on your CI system if available.  Otherwise, executed before the deploy step | 
| deploy | Executed after dependencies are resolved but before application has started | 
| post_deploy | Executed after application has been deployed and started| 
| pre_build | Executed on your CI system if available.  Otherwise, executed before the build step | 
[Action Hooks][section-mmd-tables-table1] 

OpenShift Enterprise also supports the ability for a user to schedule job to executed based upon the familiar cron functionality of linux.  Any scripts or jobs added to the minutely, hourly, daily, weekly or monthly directories will be run on a scheduled basis (frequency is as indicated by the name of the directory) using run-parts.  OpenShift supports the following schedule for cron jobs:

* daily
* hourly
* minutely
* monthly
* weekly

The markers directory will allow the user to specify to force a clean build or to hot deploy the application.

###**libs directory**

The libs directory is a location that the developer can provide any dependencies that are not able to be deployed using the standard dependency resolution system for the runtime.  In the case of PHP, the standard convention that OpenShift Enterprise uses is by providing *PEAR* modules in the deptlist.txt file.

###**misc directory**

The misc directory is a located provided to the developer for a location to store any application code that they do not want exposed to site visitors.

###**php directory**

The php directory is where all of the application code that the developer writes should be created.  By default, two files are created in this directory:

* health_check.php - A simple file to determine if the application is responding to requests
* index.php - The OpenShift template that we saw after application creation in the web browser.

##**Make a change to the PHP application and deploy updated code**

To get a good understanding of the development workflow for a user, let’s change the contents of the *index.php* template that is provided on the newly created gear.  Edit the file and look for the following code block:

	<h1>
	    Welcome to OpenShift
	</h1>

Update this code block to the following and then save your changes:

	<h1>
	    Welcome to OpenShift Enterprise
	</h1>


Once the code has been changed, we need to commit our change to the local git repository.  This is accomplished with the *git commit* command:

	$ git commit -am “Changed welcome message.”
	
Now that our code has been committed to our local repository, we need to need to push those changes up to our repository that is on the node host.  

	$ git push
	
You should see the following output:

	Counting objects: 7, done.
	Delta compression using up to 8 threads.
	Compressing objects: 100% (4/4), done.
	Writing objects: 100% (4/4), 395 bytes, done.
	Total 4 (delta 2), reused 0 (delta 0)
	remote: restart_on_add=false
	remote: httpd: Could not reliably determine the server's fully qualified domain name, using node.example.com for ServerName
	remote: Waiting for stop to finish
	remote: Done
	remote: restart_on_add=false
	remote: ~/git/firstphp.git ~/git/firstphp.git
	remote: ~/git/firstphp.git
	remote: Running .openshift/action_hooks/pre_build
	remote: Running .openshift/action_hooks/build
	remote: Running .openshift/action_hooks/deploy
	remote: hot_deploy_added=false
	remote: httpd: Could not reliably determine the server's fully qualified domain name, using node.example.com for ServerName
	remote: Done
	remote: Running .openshift/action_hooks/post_deploy
	To ssh://e9e92282a16b49e7b78d69822ac53e1d@firstphp-ose.example.com/~/git/firstphp.git/
	   3edf63b..edc0805  master -> master


Notice that we stop the application runtime (Apache), deploy the code, and then run any action hooks that may have been specified in the .openshift directory.  


##**Verify code change**

If you completed all of the steps in lab 16 correctly, you should be able to verify that your application was deployed correctly by opening up a web browser and entering the following URL:

	http://firstphp-ose.example.com
	
You should see the updated code for the application.

![](http://training.runcloudrun.com/images/firstphpOSE.png)

##**Adding a new PHP file**

To add a new source code file to your OpenShift Enterprise application is an easy and straightforward process.  For instance, if you wanted to create a PHP source code file that displays the server date and time, we create a new file located in *php* directory and name it *time.php*.  Go ahead and create this file and add the following contents:

	<?php
	// Print the date and time
	echo date('l jS \of F Y h:i:s A');
	?>

Once you have created this file, the process for pushing the changes involve adding the file to your git repository, committing the change, and then pushing the change to your OpenShift Enterprise gear.

	$ git add .
	$ git commit -am “Adding time.php”
	$ git push
	
##**Verify code change**

To verify that we have created the new PHP correctly, open up a web browser and enter the following URL:

	http://firstphp-ose.example.com/time.php
	
You should see the updated code for the application.

![](http://training.runcloudrun.com/images/firstphpTime.png)

##**Enable *hot_deploy***

If you are familiar with PHP, you will probably be wondering why we stop and start apache on each code deployment.  Fortunately, we provide a way for developers to signal to OpenShift Enterprise that they do not want us to restart the application runtime on each deployment.  This is accomplished by creating a hot_deploy marker in the correct directory.  Change the your application root directory, for example ~/code/ose/firstphp and issue the following command:

	$ touch .openshift/markers/hot_deploy
	$ git add .
	$ git commit -am “Adding hot_deploy marker”
	$ git push
	
Pay attention to the output:

	Counting objects: 7, done.
	Delta compression using up to 8 threads.
	Compressing objects: 100% (4/4), done.
	Writing objects: 100% (4/4), 403 bytes, done.
	Total 4 (delta 2), reused 0 (delta 0)
	remote: restart_on_add=false
	remote: Will add new hot deploy marker
	remote: App will not be stopped due to presence of hot_deploy marker
	remote: restart_on_add=false
	remote: ~/git/firstphp.git ~/git/firstphp.git
	remote: ~/git/firstphp.git
	remote: Running .openshift/action_hooks/pre_build
	remote: Running .openshift/action_hooks/build
	remote: Running .openshift/action_hooks/deploy
	remote: hot_deploy_added=false
	remote: App will not be started due to presence of hot_deploy marker
	remote: Running .openshift/action_hooks/post_deploy
	To ssh://e9e92282a16b49e7b78d69822ac53e1d@firstphp-ose.example.com/~/git/firstphp.git/
	   4fbda99..fdbd056  master -> master


The two lines of importance are:

	remote: Will add new hot deploy marker
	remote: App will not be stopped due to presence of hot_deploy marker


Adding a hot_deploy marker will significantly increase the speed of application deployments while developing the application.
	
**Lab 22 Complete!**
<!--BREAK-->
#**Lab 23: Managing an application (Estimated time: 5 minutes)**

**Server used:**

* localhost
* node host

**Tools used:**

* rhc

## **Start/Stop/Restart OpenShift application**

OpenShift provides commands to start,stop, and restart an application. If at any point in the future you decided that an application should be stopped for some maintenance or should not accept any request you can stop the application using the *rhc app stop* command. After making necessary maintenance tasks you can start the application again using the *rhc app start* command. 

To stop the application execute the command shown below.

	$ rhc app stop -a firstphp
	
	RESULT:
	firstphp stopped

Now if you make curl request to application url you will get 503

	$ curl http://firstphp-ose.example.com/health
	
	<!DOCTYPE HTML PUBLIC "-//IETF//DTD HTML 2.0//EN">
	<html><head>
	<title>503 Service Temporarily Unavailable</title>
	</head><body>
	<h1>Service Temporarily Unavailable</h1>
	<p>The server is temporarily unable to service your
	request due to maintenance downtime or capacity
	problems. Please try again later.</p>
	<hr>
	<address>Apache/2.2.15 (Red Hat) Server at myfirstapp-ose.example.com Port 80</address>
	</body></html>


To Start the application, execute the command shown below.

	$ rhc app start -a firstphp

	RESULT:
	firstphp started

Now if you make curl request you will get 1 as response

	$ curl http://firstphp-ose.example.com/health
	
	1
	

You can also stop and start the application in one command as shown below.

	$ rhc app restart -a firstphp

	RESULT:
	firstphp restarted


##**View application details**

All the details about an application can be viewed by the *rhc app show* command. This command will list when the application was created, unique identifier of the application, git URL, SSH URL, and many other details as shown below:


	$ rhc app show -a firstphp
	Password: ****
	
	
	firstphp @ http://firstphp-ose.example.com/
	===========================================
	  Application Info
	  ================
	    UUID      = e9e92282a16b49e7b78d69822ac53e1d
	    Git URL   = ssh://e9e92282a16b49e7b78d69822ac53e1d@firstphp-ose.example.com/~/git/firstphp.git/
	    Gear Size = small
	    Created   = 1:47 PM
	    SSH URL   = ssh://e9e92282a16b49e7b78d69822ac53e1d@firstphp-ose.example.com
	  Cartridges
	  ==========
	    php-5.3
    


##**View application status**

The state of application gears can be viewed by passing *state* flag to the *rhc app show* command as shown below:


	rhc app show --state -a firstphp
	Password: ****
	
	
	RESULT:
	Geargroup php-5.3 is started


##**Cleaning up an application**

As users start developing an application and deploying changes to OpenShift Enterprise, the application will start consuming some of the available disk space that is part of their quota. The space is consumed by the git repository, log files, temp files, and unused application libraries. OpenShift provides a disk space cleanup tool to help users manage the application disk space. This command is also available under *rhc app* and performs the following functions:

* Runs the git gc command on the application's remote git repository
* Clears the application's /tmp and log file directories. These are specified by the application's *OPENSHIFT_LOG_DIR** and *OPENSHIFT_TMP_DIR* environment variables.
* Clears unused application libraries. This means that any library files previously installed by a git push command are removed.

To clean up the disk run the command as shown below.

	$ rhc app tidy -a firstphp

##**SSH to application gear**

OpenShift allows remote access to the application via the Secure Shell protocol (SSH). [Secure Shell (SSH)](http://en.wikipedia.org/wiki/Secure_Shell) is a network protocol for securely getting access to a remote computer. SSH uses RSA public key cryptography for both connection and authentication. SSH provides direct access to the command line of your application gear on the remote server. After you are logged in on the remote server you can use the command line to directly manage the server, check logs and test quick changes. OpenShift Enterprise uses SSH for :

* Performing Git operations.
* Remote access your application gear.

The SSH keys were generated and uploaded to OpenShift Enterprise by rhc setup command we executed in a previous lab. You can verify that SSH keys are uploaded by logging into OpenShift Enterprise web console and clicking on the "My Account" tab as shown below.

![](http://training.runcloudrun.com/images/sshkeys.png)

**Note:** If you don't see any entry under "Public Keys" then you can either upload the SSH keys by clicking on "Add a new key" or run the *rhc setup* command again. This will create an ssh keypair in <User.Hom>/.ssh folder if not present and upload to OpenShift server.

After the SSH keys are uploaded, you can SSH into the application gear as shown below. SSH is installed by default on most UNIX like platforms such as Mac OS X and Linux. For windows, you can use [Putty](http://www.chiark.greenend.org.uk/~sgtatham/putty/). Instructions for installing Putty can be found [on the OpenShift website](https://openshift.redhat.com/community/page/install-and-setup-putty-ssh-client-for-windows). 

	$ ssh UUID@appname-namespace.example.com

You can get the SSH URL by running *rhc app show* command as shown below:


	$ rhc app show -a firstphp
	Password: ****
	
	
	firstphp @ http://firstphp-ose.example.com/
	===========================================
	  Application Info
	  ================
	    Created   = 1:47 PM
	    UUID      = e9e92282a16b49e7b78d69822ac53e1d
	    SSH URL   = ssh://e9e92282a16b49e7b78d69822ac53e1d@firstphp-ose.example.com
	    Gear Size = small
	    Git URL   = ssh://e9e92282a16b49e7b78d69822ac53e1d@firstphp-ose.example.com/~/git/firstphp.git/
	  Cartridges
	  ==========
	    php-5.3```

Now you can ssh into the application gear using the SSH Url shown above

	$ ssh e9e92282a16b49e7b78d69822ac53e1d@firstphp-ose.example.com
	
	    *********************************************************************
	
	    You are accessing a service that is for use only by authorized users.  
	    If you do not have authorization, discontinue use at once. 
	    Any use of the services is subject to the applicable terms of the 
	    agreement which can be found at: 
	    https://openshift.redhat.com/app/legal
	
	    *********************************************************************
	
	    Welcome to OpenShift shell
	
	    This shell will assist you in managing OpenShift applications.
	
	    !!! IMPORTANT !!! IMPORTANT !!! IMPORTANT !!!
	    Shell access is quite powerful and it is possible for you to
	    accidentally damage your application.  Proceed with care!
	    If worse comes to worst, destroy your application with 'rhc app destroy'
	    and recreate it
	    !!! IMPORTANT !!! IMPORTANT !!! IMPORTANT !!!
	
	    Type "help" for more info.
	


You can also view all the commands available on the application gear shell by running help command as shown below.

	[firstphp-ose.example.com ~]\> help
	Help menu: The following commands are available to help control your openshift
	application and environment.
	
	ctl_app         control your application (start, stop, restart, etc)
	ctl_all         control application and deps like mysql in one command
	tail_all        tail all log files
	export          list available environment variables
	rm              remove files / directories
	ls              list files / directories
	ps              list running applications
	kill            kill running applications
	mysql           interactive MySQL shell
	mongo           interactive MongoDB shell
	psql            interactive PostgreSQL shell
	quota           list disk usage
	

##**Adding a custom domain to an application**

OpenShift Enterprise supports the use of custom domain names for an application.   For example, let's suppose we want to use http://www.somesupercooldomain.com domain name for the application *firstphp* we created in a previous lab. The first thing you need to do before setting up a custom domain name is to buy the domain name from domain registration provider.

After buying the domain name, you have to add a [CName record](http://en.wikipedia.org/wiki/CNAME_record) in for the custom domain name.  Once you have created the CName record, you can let OpenShift Enterprise know about the CName by using the *alias* switch.

	$ rhc alias add firstphp www.mycustomdomainname.com
	
Technically, what OpenShift Enterprise has done under the hoods is set up a Vhost in Apache to handle the custom URL.

**Lab 23 Complete!**
<!--BREAK-->