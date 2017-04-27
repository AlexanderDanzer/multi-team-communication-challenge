# Multi Team Communication Evaluation

This software will be used at this year's Technical Challenge [Multi Team Communication](http://wiki.robocup.org/Small_Size_League/RoboCup_2017/Multi_Team_Communication)

## Purpose
None of this software is necessary to compete in the Technical Challenge.
It is only the evaluation software which you can use to test your system.
It is also the reference system for deciding if the messages were properly sent.
If you find any bugs or encounter problems with the Protobuf messaging, please
contact the TC.

## Usage
You need the [ER-Force Framework](https://github.com/robotics-erlangen/framework)
in order to run this evaluation software.
Please refer to the file [COMPILE.md](https://github.com/robotics-erlangen/framework/blob/master/COMPILE.md)
for compilation instructions.

Compile and start `ra`. Click on the button "Strategy disabled" in the color of your
robots and choose the file `mixed-team-evaluation/init.lua` of this repository

You can select evaluators for the different tasks in the dropdown-menu in bottom left corner.

The check-boxes in the "visualizations" widget to the right allow to
highlight the mixed-team messages graphically.

![Ra](http://wiki.robocup.org/images/b/b3/Ssl_technicalChallenge2017_eval.png)


## Message Forwarding
In order to use the software as messaging forwarder in the way it will be done
at RoboCup 2017, click on "Configuration" and enter the Slave Team's IP under
Mixed Team. Ra listens on port 10012 for incoming messages of the Master Team.


## Testing
`mixed-team-test/init.lua` can be used like the evaluation script and  sends an
example team plan, not corresponding to any task of the challenge.
You can use it to test basic functionality.

[1]: http://wiki.robocup.org/Small_Size_League/RoboCup_2017/Multi_Team_Communication
