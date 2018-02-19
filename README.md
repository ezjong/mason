# Mason

**Mason** is a collection of scripts that help you to create isolated packaged
environments. Think *Docker*, but much lighter. Think *virtual env*, but more
powerful.

As Mason automatically adds a well-proven packager manager (Linuxbrew/Homebrew),
it is able to provide you with apt-get like powers without the necessarity of being root.

### Dependencies  
perl
bash

### Directory tree

| **mason/**       | **../bin**      | **../gravel**   | **../images**       |
|------------------|-----------------|-----------------|---------------------|
| root directory   |   mason binary  | submodules      | distribution images |

### Setting up environments
Set an environment variable ENVIRONMENTS_HOME which will serve as a root folder for environments.

We recommend ```~/Environments```

If you have no clue how to do this, just run this on the terminal:

```
~$ touch ~/.profile && echo "export ENVIRONMENTS_HOME=$HOME/Environments"  >> ~/.profile
```

### Choose an image script
Choose an appropriate image script for your OS.

If you are on a GPU server, you can identify your OS via

```
~$ lsb_release -a
```

### Install
You may need to make the script executable via

```
~/mason/images$ chmod +x ./image_script
```

If done, you can run the installer via

```
~/mason/images$ ./install_script
```

The installer will ask you for an ENVIRONMENT name, however, the rest should be done automatically.
This may take a few minutes. The process create a local anaconda environment as well as a bashrc script to setup your shell.

### Startup
When finished, you can either source the created bashrc file

```
~/Environments/ENVIRONMENT$ source ./env.bashrc
```

or alternatively you can use mason

```
mason load ENVIRONMENT
```
