void setup() {
  Serial.begin(9600);
  pinMode (20, OUTPUT);
  digitalWrite(20, LOW);
}

void loop() {
  char lst = Serial.read();
  if(lst == '1'){
    digitalWrite(20, HIGH);
  }
  else if(lst == '2'){
    digitalWrite(20, LOW);
  }
}
