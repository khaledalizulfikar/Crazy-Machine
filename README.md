# Crazy-Machine
![image](https://github.com/user-attachments/assets/ad5578d1-2113-4c6b-a9a4-8266c5ce4595)

The Crazy Machine Project consists of designing, constructing and implementing a marble machine which runs for approximately 1 minute. The machine must fit the design requirements of using fixed entry and exit points, keeping the ball within the confines of the box and using a minimum number of different sensors and actuators in the design. Additionally, the machine should be reliable enough to perform a demonstration and should reset to its initial state following the completion of the machine. The machine should feature different combinations of sensors and actuators and operate using a mixture of Arduino and FPGA code with some form of communication between these devices.
The goal of our machine is to create a marble run where the different sections of the machine are able to be completed interchangeably. To achieve this, our machine is comprised of a central loop consisting of a marble splitter which determines the path of the ball, 4 different paths for the ball to take and a lift to return the ball to the starting position. As such the machine comprises of splitter, ball return, marble lift and 4 different sections that can be completed interchangeably. In order to allow the selection of the path of the ball, several buttons are used prior to entering the ball. These buttons are optional, with the machine falling back to a random order if user input is not provided. The expected process for the machine is:

1.The order of the sections is set, and the splitter is set to the selected path.
2.The ball is entered into the machine.
3.Sections 1-4 are completed in the specified order, with the ball returning to the starting position using a marble lift.
4.The splitter is set to the exit path and the ball exits the machine.

The theme of our machine is "Steampunk", allowing for mechanical motifs which are integrated into the different sections of the machine and the decoration. The decoration of the machine heavily features recycled components and is stylised towards a cobbled-together steampunk design. The different sections of our machine were designed with this in mind, featuring mechanical designs where “form follows function” rather than the other way around.
