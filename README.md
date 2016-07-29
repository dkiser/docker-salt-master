# docker-salt-master

A Docker image which allows you to run a containerized Salt-Master server with an optional [Multi-Master-PKI](http://docs.saltstack.com/en/latest/topics/tutorials/multimaster_pki.html) setup.

>NOTE: salt master config must have ```user: salt``` as this container runs unprivileged!

## Running the Container

You can easily run the container like so:

    docker run --rm -it dkiser/salt-master

## Environment Variables

The following environment variables can be set:

* `LOG_LEVEL`: The level to log at, defaults to `error`

## Volumes

There are several volumes which can be mounted to Docker data container as
described here: https://docs.docker.com/userguide/dockervolumes/. The following
volumes can be mounted:

 * `/etc/salt` - This contains the master config file
 * `/etc/salt/pki` - This holds the Salt Minion authentication keys
 * `/var/cache/salt` - Job and Minion data cache
 * `/var/log/salt` - Salts log directory
 * `/etc/salt/master.d` - Master configuration include directory
 * `/srv/salt` - Holds your states, pillars etc if not using gitfs backend

### Data Container

To create a data container you are going to want the thinnest possible docker
image, simply run this docker command, which will download the simplest possible
docker image:

    docker run -v /etc/salt /etc/salt/pki -v /var/salt/cache -v /var/log/salt -v /etc/salt/master.d -v /srv/salt --name salt-master-data busybox true

This will create a stopped container wwith the name of `salt-master-data` and
will hold our persistent salt master data. Now we just need to run our master
container with the `--volumes-from` command:

    docker run --rm -it --volumes-from salt-master-data dkiser/salt-master

### Sharing Local Folders

To share folders on your local system so you can have your own master
configuration, states, pillars etc just alter the `salt-master-data`
command:

```bash
docker run -it -v /path/to/local/etc/salt/pki:/etc/salt/pki -v /path/to/loca/etc/salt:/etc/salt -v /path/to/loca/etc/salt/master.d:/etc/salt/master.d -v /path/to/loca/var/log/salt/:/var/log/salt --name salt-master-data busybox /bin/true
```

Now `/path/to/local` can hold your states, master configuration, minion/master pki, and logs.

>Make sure uid:gid permissions match the salt user and group in the salt-master container for any items in locally shared folders!
```bash
docker run dkiser/salt-master "/usr/bin/id"
uid=999(salt) gid=999(salt) groups=999(salt)
```

#### OSX boot2docker

If you are using OSX boot2docker, there is an issue where the VirtualBox '''vboxfs''' share used in the boot2docker vm does not allow for ACL's to properly share from local folders to the containers within the boot2docker VM. Perform the workaround below to switch from ```vboxfs``` to ```nfs``` mounted shares on OSX.

1. Make sure OSX firewall allows nfs (e.g. "Block all incomming connections" is NOT checked)
2. Create/Modify ```/etc/exports``` on your OSX host as below, substituting your boot2docker ip as appropriate.
```bash
/Users [boot2dockerip]
```
3. ```sudo nfsd update``` on the OSX host
4. ```boot2docker ssh``` to ssh into the boot2docker vm
5. ```sudo umount /Users```
6. ```sudo /usr/local/etc/init.d/nfs-client start```
7. ```sudo mount 192.168.59.3:/Users /Users -o  rw,async,noatime,rsize=32768,wsize=32768,proto=tcp```

## Ports

The following ports are exposed:

 * `4505`
 * `4506`

These ports allow minions to communicate with the Salt Master.

## Running Salt Commands

Utilize ```docker exec``` in order to jump into the salt master and execute Salt commands.

Once installed run:

    $ docker exec salt-master /bin/bash
    $ salt '*' test.ping
    $ salt '*' grains.items

## Example

> Note: If on OSX, the temp path must be in /Users somehwere (boot2docker limitation)

### Config/Launch salt-master
1. Create a directory to stage an example data set to seed the salt-master with via volumes.
```bash
mkdir -p /tmp/salt_test/master/etc/salt
export SALT_DEV_MASTER=/tmp/salt_test/master
```
2. Create a minimal master config file.
```bash
echo "user: salt" > $SALT_DEV_MASTER/etc/salt/master
```
3. Chown the host container volume contents for the uid:gid of salt in the container.
```bash
sudo chown -R 999:999 $SALT_DEV_MASTER/etc/salt
```
4. Create the data only container with volume mapping to seed our salt-master container.
```bash
docker run -it -v $SALT_DEV_MASTER/etc/salt:/etc/salt --name salt-master-data busybox /bin/true
```
5. Run the salt-master container with our volumes.
```bash
docker run --rm -it --name salt-master --volumes-from salt-master-data -e LOG_LEVEL=debug -p 4505:4505 -p 4506:4506 dkiser/salt-master
```

### Config/Launch salt-minion
1. Create a directory to stage an example data set to seed the salt-minion with via volumes.
```bash
mkdir -p /tmp/salt_test/minion/etc/salt
export SALT_DEV_MINION=/tmp/salt_test/minion
```
2. Create a minimal minion config file (adjust master IP/hotname accordingly, example is a boot2docker ip)
```bash
echo "user: salt" > $SALT_DEV_MINION/etc/salt/minion
echo "master: 192.168.59.103" >> $SALT_DEV_MINION/etc/salt/minion
```
3. Chown the host container volume contents for the uid:gid of salt in the container.
```bash
sudo chown -R 999:999 $SALT_DEV_MINION/etc/salt
```
4. Create the data only container with volume mapping to seed our salt-minion container.
```bash
docker run -it -v $SALT_DEV_MINION/etc/salt:/etc/salt --name salt-minion-data busybox /bin/true
```
5. Run the salt-minion container with our volumes.
```bash
docker run --rm -it --name salt-minion --volumes-from salt-minion-data -e LOG_LEVEL=debug dkiser/salt-minion
```

### Accept keys on salt-master
1. ```docker exec -it salt-master /bin/bash```
2. Check to see if minion talked to master yet
```bash
$ salt-key -L
Accepted Keys:
Denied Keys:
Unaccepted Keys:
78e1a9c58485
Rejected Keys:
```
3. Accept the Key
```bash
$ salt-key -A
The following keys are going to be accepted:
Unaccepted Keys:
78e1a9c58485
Proceed? [n/Y] y
Key for minion 78e1a9c58485 accepted.
```
4. Test communication
```bash
$ salt '*' test.ping
78e1a9c58485:
    True
```
