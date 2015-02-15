// Motor Drivers for Vertebot's Arduino
// Written by Christopher Harris, vertebot.com

// Initialize pins
int RB_pwm = 2;
int RB_dir = 3;
int RF_pwm = 5;
int RF_dir = 6;
int LB_pwm = 8;
int LB_dir = 9;
int LF_pwm = 11;
int LF_dir = 12;
int led = 53;

// Initialize variables
int manual_command[] = {0, 0, 0};
int L_torque = 0;
int R_torque = 0;
int reverse = 0;

// Setup
void setup() {                
  pinMode(RB_pwm, OUTPUT);
  pinMode(RB_dir, OUTPUT);
  pinMode(RF_pwm, OUTPUT);
  pinMode(RF_dir, OUTPUT);
  pinMode(LB_pwm, OUTPUT);
  pinMode(LB_dir, OUTPUT);
  pinMode(LF_pwm, OUTPUT);
  pinMode(LF_dir, OUTPUT);
  pinMode(led, OUTPUT);
  Serial.begin(115200);
}

// Main loop
void loop() {   

  delay(1000);

   // Get motor commands from bluetooth
  if(Serial.available() == 3) {
    manual_command[0] = Serial.read();
    manual_command[1] = Serial.read();
    manual_command[2] = Serial.read();
  }
  
  L_torque = manual_command[0];
  R_torque = manual_command[1];
  reverse = manual_command[2];
  
  // Send motor commands to pins
  if(reverse == 1){ 
    analogWrite(RB_pwm, 255);
    digitalWrite(RB_dir, 1);    
    analogWrite(RF_pwm, 255);
    digitalWrite(RF_dir, 0); 
    analogWrite(LB_pwm, 255);
    digitalWrite(LB_dir, 1);    
    analogWrite(LF_pwm, 255);
    digitalWrite(LF_dir, 0);
    digitalWrite(led, 1); 
  }
  else{ 
    analogWrite(RB_pwm, L_torque);
    digitalWrite(RB_dir, 0);    
    analogWrite(RF_pwm, L_torque);
    digitalWrite(RF_dir, 1); 
    analogWrite(LB_pwm, R_torque);
    digitalWrite(LB_dir, 0);    
    analogWrite(LF_pwm, R_torque);
    digitalWrite(LF_dir, 1);
    digitalWrite(led, 0); 
   }
 }
