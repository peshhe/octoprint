# OctoPrint for Docker with support of up to 2 camera streams 
As described in the [official "OctoPrint/octoprint-docker" repo](https://github.com/OctoPrint/octoprint-docker) you will need to declare a few environment variables in the [`docker-compose.yml`](docker-compose.yml) file in order to determine whether to start [jacksonliam's `mjpg-streamer`](https://github.com/jacksonliam/mjpg-streamer) service for one or tho camera devices.


I have introduced a new environment variable called **`SECOND_CAMERA_DEV`** that if exists will start another instance of the `mjpg-streamer` service which will still be managed (and monitored) by `s6-svc`. This env var can be seen in the ```docker-compose.yml``` file. Please note that you will need to point the correct camera devices (usually located in */dev/video0*, */dev/video2*, etc.)


> **_NOTE:_** The same approach can be used to add support for more cameras. If you need help with that please feel free to contact me at p.karadzhovv@gmail.com.

## What has been modified?
Added files:
* /root/etc/cont-init.d/[*02-second-mjpg-streamer-config*](root/etc/cont-init.d/02-second-mjpg-streamer-config) - will check if `SECOND_CAMERA_DEV` environment variable exists and if not will remove the `second-streamer` service.
* /root/etc/services.d/[*second-streamer/run*](root/etc/services.d/second-streamer/run) - will run another instance of `mjpg-streamer` service (and process) for the second camera.

</br>

The modified files are:
* [*Dockerfile*](Dockerfile) - I've optimized the *Dockerfile* a bit with adding cleaning steps after some of the **```RUN```** instructions and combining multiple commands in single **```RUN```** in order to make the final image smaller in size.
* [*docker-compose.yml*](docker-compose.yml) - I referred to my image and I've included all the env vars necessary for running two cameras
* /root/etc/haproxy/[*haproxy.cfg*](root/etc/haproxy/haproxy.cfg) - added another `backend` to allow access to the second camera's stream (url of the second stream is `http://IP-of-docker-host/`**`second`**`/?action=stream`, while the first camera's stream stays `http://IP-of-docker-host/`**`webcam`**`/?action=stream`)
* /root/octoprint/[*octoprint/config.yaml*](root/octoprint/octoprint/config.yaml) - added temperature profiles for ABS and PLA filaments (completely not needed - I did it just for testing purposes)

</br>

##
If you have any questions or improvements please send them to p.karadzhovv@gmail.com - I'll be happy to answer you!

##
I  excluded all the files from the [original repo](https://github.com/OctoPrint/octoprint-docker), to show just the needed ones for this task.

This has been done on 18th Oct 2023.
