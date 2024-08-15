#include <Stepper.h>
#include <string.h>
#include <SoftwareSerial.h>

// #include <SD.h>          // Need to include the SD library
// #define SD_ChipSelectPin 53 // Connect pin 4 of Arduino to CS pin of SD card
// #include <TMRpcm.h>     // Arduino library for asynchronous playback of PCM/WAV files
// #include <SPI.h>        // Need to include the SPI library

// TMRpcm tmrpcm; // Create an object for use in this sketch

SoftwareSerial SoftSerial(2, 3); // RX, TX

int stations[5] = {1, 2, 3, 4, 5}; // exit is station 5

int stationMap[5] = {B01000110, B01000111, B01001000, B01001001, B01001010};
String soundMap[5] = {"a1.wav", "a2.wav", "a3.wav", "a4.wav", "a5.wav"};

int station_count;
int one_set;
int two_set;
int three_set;
int four_set;
int stations_completed;
int station_sound_play;
int lift_pin = 10;

int force = 0;
const int sensorPin = A0;    
const int stepsPerRev = 64;  
// 15, 16, 17, 18
Stepper leaStepper(stepsPerRev, 15, 17, 16, 18); 
Stepper liamStepper(stepsPerRev, 4, 6, 5, 7); 
int current_count = 0;
int target_position = 0;
int liam_count = 0;
int liam_target = 0;

int sensorValue = 0;   

void replace(int value, int index) {
  Serial.println("val: " + String(value) + " index: " + String(index));
  stations[index] = value;
}

void print_array(int arr[]) {
  for (int i=0; i<5; i++) {
    Serial.println(arr[i]);
  }
}

void send_station(int arr[]) {
  if (stations_completed <= 4) {
    SoftSerial.write(stationMap[arr[stations_completed] - 1]); //get corresponding station # and convert it to the bytecode
    Serial.print(arr[stations_completed] - 1);
    Serial.print(" ");
    Serial.println(stationMap[arr[stations_completed] - 1]);
    // tmrpcm.play(soundMap[arr[stations_completed] - 1]);
    Serial.print("Soundmap: ");
    Serial.println(soundMap[arr[stations_completed] - 1]);
    if (arr[stations_completed] == 4) {
      liam_target = 60 * 512;
      liam_count = 0;
    }
    stations_completed++;
  } else {
    Serial.println("Error: stations out of range");
  }
}

void lea_spin() {
  if (current_count < target_position) {
    Serial.println(current_count);
    leaStepper.step(128);
    current_count += 128;
    Serial.println(target_position);
    Serial.println(current_count);
  }
}

void liam_spin() {
  if (liam_count < liam_target) {
    Serial.println(liam_count);
    liamStepper.step(-512);
    liam_count += 512;
  }
}
void start_lift() {
  pinMode(lift_pin, OUTPUT);
  int speed = 50;
  while (speed < 255) {
    analogWrite(lift_pin, speed);
    speed++;
    delay(10);
  }
  // delay(3000);
  // analogWrite(lift_pin, 180);
  // delay(3000);
  // analogWrite(lift_pin, 255);
  // delay(3000);
}

void setup() {
  // tmrpcm.speakerPin = 46; // 5, 6, 11, or 46 on Mega, 9 on Uno, Nano, etc
  // if (!SD.begin(SD_ChipSelectPin)) // Returns 1 if the card is present
  // {
  //   Serial.println("SD fail");
  //   return;
  // }
  // tmrpcm.setVolume(5); // Set volume

  Serial.begin(9600);
  // Serial2.begin(9600, SERIAL_8N1, 16, 17);
  SoftSerial.begin(9600);
  delay(1000);

  for (int i = 0; i < 4; i++) {
    int index = random(0, 4);
    int temp = stations[i];
    stations[i] = stations[index];
    stations[index] = temp;
  }
  print_array(stations);

  station_count = 0;
  one_set = 0;
  two_set = 0;
  three_set = 0;
  four_set = 0;
  stations_completed = 0;
  station_sound_play = 0;

  leaStepper.setSpeed(350);  
  liamStepper.setSpeed(350); 
}

void loop() {
  int signal = SoftSerial.read();
  
  int test_signal = Serial.read();
  if (test_signal > 0) {
    SoftSerial.write(test_signal);
    signal = test_signal;
    Serial.println(test_signal);
  }

  // switch case for playing the buttons
  if (station_sound_play == 0) {
    switch (station_count)
    {
    case 0:
      Serial.println("Playing first.wav");
      // tmrpcm.play("first.wav");
      station_sound_play = 1;
      break;
    case 1:
      Serial.println("Playing second.wav");
      // tmrpcm.play("second.wav");
      station_sound_play = 1;
      break;
    case 2:
      Serial.println("Playing third.wav");
      // tmrpcm.play("third.wav");
      station_sound_play = 1;
      break;
    case 3:
      Serial.println("Playing fourth.wav");
      // tmrpcm.play("fourth.wav");
      station_sound_play = 1;
      break;
    default:
      break;
    }
  }

  if (stations_completed > 4) {
    stations_completed = 0;
    station_sound_play = 0;
    one_set = 0;
    two_set = 0;
    three_set = 0;
    four_set = 0;
  }

  // This if-else statement is for setting the array with the buttons 
  if (signal == 65) {
    if (!one_set) {
      Serial.println("Station 1");
      replace(1, station_count);
      // tmrpcm.play("i1.wav");
      Serial.println("Playing Station 1");
      station_count++;
      station_sound_play = 0;
      one_set = 1;
      delay(100); // tune to length of sound
    }
  }
  else if (signal == 66) {
    if (!two_set) {
      Serial.println("Station 2");
      replace(2, station_count);
      // tmrpcm.play("i2.wav");
      Serial.println("Playing Station 2");
      station_count++;
      station_sound_play = 0;
      two_set = 1;
      delay(100); // tune to length of sound
    }
  }
  else if (signal == 67) {
    if (!three_set) {
      Serial.println("Station 3");
      replace(3, station_count);
      // tmrpcm.play("i3.wav");
      Serial.println("Playing Station 3");
      station_count++;
      station_sound_play = 0;
      three_set = 1;
      delay(100); // tune to length of sound
    }
  }
  else if (signal == 68) {
    if (!four_set) {
      Serial.println("Station 4");
      replace(4, station_count);
      // tmrpcm.play("i4.wav");
      Serial.println("Playing Station 4");
      station_count++;
      station_sound_play = 0;
      four_set = 1;
      delay(100); // tune to length of sound
    }
  } 
  // prints non-null messages recieved
  else
  {
    if (signal != -1) {
      Serial.println(signal);
    }
  }

  // This code resets the button logic once a sequence has been entered & sends the first servo position
  if (station_count == 4) {
    print_array(stations);
    //send byte for first station
    station_count = 0;
    one_set = 0;
    two_set = 0;
    three_set = 0;
    four_set = 0;
    stations_completed = 0;
    station_sound_play = 1;
    Serial.println("Playing ready.wav");
    send_station(stations);
    start_lift();
    // tmrpcm.play("ready.wav");
  }

  // line sensor trigger
  if (signal == 69) {
    Serial.println("Station completed sending next");
    liam_target = 0;
    send_station(stations);
    delay(1000);
  }


  // add code for processing other requests such as LEDs
  // if (signal == XX) {
    // do something
  // }

  sensorValue = analogRead(sensorPin);
  
 //Serial.println(sensorValue);
  if (signal == 80) {
    sensorValue = 50;
  }
  // Check if the sensorValue exceeds threshold toggle later
    if (sensorValue < 800) {
      delay(100);
      target_position = 64 * 64; 
      current_count = 0;      
    } 

  lea_spin();
  liam_spin();
}
