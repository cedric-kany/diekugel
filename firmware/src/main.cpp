/*************************************
 *  Team 4 ~ Physik 3 Projektarbeit  *
 *  Cedric Kany 2022                 *
 *  Steuerung der Kugel              *
 *************************************/

#include <Arduino.h>

#include <BLEDevice.h>
#include <BLEUtils.h>
#include <BLEServer.h>
#include <BLE2902.h>

#include <ESP32Servo.h>
#include <FastLED.h>
#include <Adafruit_MPU6050.h>
#include <Adafruit_Sensor.h>
#include <Wire.h>

// Servo Definitions
#define SPIN_SERVO_PIN 4
#define ROT_SERVO_PIN 5
#define SERVO_MIN 400
#define SERVO_MAX 2400

// Bluetooth Definitions
#define SERVICE_UUID "033b3bbd-7750-4d23-8572-6d75e07895a7"
#define CHARACTERISTIC_UUID_FREQ "7f005c00-c0d6-491c-a999-9186af064d67"
#define CHARACTERISTIC_UUID_ROT_ANGLE "7f005c01-c0d6-491c-a999-9186af064d67"
#define CHARACTERISTIC_UUID_STATUS "7f005c02-c0d6-491c-a999-9186af064d67"

// I2C Definitions
#define I2C_SCL 11
#define I2C_SDA 10

// RGB LED DEFINITIONS
#define NUM_LEDS_STAND 38
#define NUM_LEDS_KUGEL 23

#define LED_DATA_PIN_STAND 2
#define LED_DATA_PIN_KUGEL 1

#define LED_TYPE WS2812B
#define COLOR_ORDER GRB
#define VOLTS 5
#define MAX_MA 1000

#define SERVO_SPEED 128 // spin servo speed, maximum 128

// KUGEL STATUS
#define STATUS_STOPPED 0
#define STATUS_RUNNING 1
#define STATUS_MEASURING 2

Servo servoSpin;
Servo servoRot;
int servoDirection = 1;

TwoWire I2C_MPU = TwoWire(0);

// Filter Settings
double emaGyroZAlpha = 0.025;
double emaGyroZ = 0;
double emaAccelXAlpha = 0.025;
double emaAccelX = 0;

uint16_t freq = 700;
uint16_t rotAngle = 0;
uint16_t status = STATUS_STOPPED;
int8_t direction = 1;

Adafruit_MPU6050 mpu;

CRGBArray<NUM_LEDS_STAND> ledsStand;
CRGBArray<NUM_LEDS_KUGEL> ledsKugel;

BLECharacteristic *pFreqCharacteristic;
BLECharacteristic *pRotAngleCharacteristic;
BLECharacteristic *pStatusCharacteristic;

class FreqCallback : public BLECharacteristicCallbacks
{
  void onWrite(BLECharacteristic *pCharacteristic)
  {
    std::string value = pCharacteristic->getValue();

    if (value.length() > 0)
    {
      // freq = atoi(value.c_str());

      if (atoi(value.c_str()) >= 30000)
      {
        direction *= -1;
      }
      else
      {
        freq = atoi(value.c_str());
      }
      Serial.println("*********");
      Serial.print("New freq x value: ");
      Serial.println(freq);
      Serial.println("*********");
    }
  }
};

class RotAngleCallback : public BLECharacteristicCallbacks
{
  void onWrite(BLECharacteristic *pCharacteristic)
  {
    std::string value = pCharacteristic->getValue();

    if (value.length() > 0)
    {
      rotAngle = atoi(value.c_str());
      Serial.println("*********");
      Serial.print("New rot angle value: ");
      Serial.println(rotAngle);
      Serial.println("*********");
      if (rotAngle >= 0.0 && rotAngle <= 90.0)
      {
        servoRot.write(rotAngle);
      }
    }
  }
};

class StatusCallback : public BLECharacteristicCallbacks
{
  void onWrite(BLECharacteristic *pCharacteristic)
  {
    std::string value = pCharacteristic->getValue();

    if (value.length() > 0)
    {
      status = atoi(value.c_str());
      Serial.println("*********");
      Serial.print("New status value: ");
      Serial.println(status);
      Serial.println("*********");
    }
  }
};

void measureFrequency(uint16_t, double);
bool checkIfZero(double);
void runServo(uint16_t, void (*)(int8_t));
void stopServo();
void onDirChange(int8_t);
void getIMUData();
void fillLEDs(CRGB, uint8_t, CRGB[]);

void setup()
{
  Serial.begin(115200);
  Serial.println("Starting BLE...");

  I2C_MPU.begin(I2C_SDA, I2C_SCL, 100000);

  servoSpin.attach(SPIN_SERVO_PIN, SERVO_MIN, SERVO_MAX);
  servoRot.attach(ROT_SERVO_PIN, 300, 2600);

  servoRot.write(0);

  if (!mpu.begin(104U, &I2C_MPU))
  {
    Serial.println("Failed to find MPU6050 chip");
    while (1)
    {
      delay(10);
    }
  }

  mpu.setAccelerometerRange(MPU6050_RANGE_4_G);
  mpu.setGyroRange(MPU6050_RANGE_250_DEG);
  mpu.setFilterBandwidth(MPU6050_BAND_21_HZ);

  BLEDevice::init("Die Kugel");

  BLEServer *pServer = BLEDevice::createServer();
  BLEService *pService = pServer->createService(SERVICE_UUID);

  pFreqCharacteristic = pService->createCharacteristic(
      CHARACTERISTIC_UUID_FREQ,
      BLECharacteristic::PROPERTY_READ |
          BLECharacteristic::PROPERTY_WRITE | BLECharacteristic::PROPERTY_NOTIFY);

  pRotAngleCharacteristic = pService->createCharacteristic(
      CHARACTERISTIC_UUID_ROT_ANGLE,
      BLECharacteristic::PROPERTY_READ |
          BLECharacteristic::PROPERTY_WRITE);
  pStatusCharacteristic = pService->createCharacteristic(
      CHARACTERISTIC_UUID_STATUS,
      BLECharacteristic::PROPERTY_READ |
          BLECharacteristic::PROPERTY_WRITE | BLECharacteristic::PROPERTY_NOTIFY);

  pFreqCharacteristic->setCallbacks(new FreqCallback());
  pRotAngleCharacteristic->setCallbacks(new RotAngleCallback());
  pStatusCharacteristic->setCallbacks(new StatusCallback());

  pFreqCharacteristic->addDescriptor(new BLE2902());
  pStatusCharacteristic->addDescriptor(new BLE2902());

  pFreqCharacteristic->setValue(freq);
  pRotAngleCharacteristic->setValue(rotAngle);
  pStatusCharacteristic->setValue(status);

  pService->start();
  BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->addServiceUUID(SERVICE_UUID);
  pAdvertising->setScanResponse(true);
  pAdvertising->setAppearance(0x05c0);
  pAdvertising->setMinPreferred(0x06);
  pAdvertising->setMinPreferred(0x12);
  BLEDevice::startAdvertising();

  FastLED.setMaxPowerInVoltsAndMilliamps(VOLTS, MAX_MA);

  FastLED.addLeds<LED_TYPE, LED_DATA_PIN_KUGEL, COLOR_ORDER>(ledsKugel, NUM_LEDS_KUGEL)
      .setCorrection(TypicalLEDStrip);
  FastLED.addLeds<LED_TYPE, LED_DATA_PIN_STAND, COLOR_ORDER>(ledsStand, NUM_LEDS_STAND)
      .setCorrection(TypicalLEDStrip);

  Serial.println("Die Kugel is ready");

  fillLEDs(CRGB::Black, NUM_LEDS_KUGEL, ledsKugel);
  fillLEDs(CRGB::Black, NUM_LEDS_STAND, ledsStand);
  // turn on anmimation

  for (uint8_t i = 0; i < NUM_LEDS_STAND; i++)
  {
    ledsStand[i] = CRGB::Green;
    FastLED.show();
    delay(25);
  }

  fillLEDs(CRGB::Black, NUM_LEDS_KUGEL, ledsKugel);
  fillLEDs(CRGB::Black, NUM_LEDS_STAND, ledsStand);
  for (int j = 0; j < 255; j++)
  {
    for (int i = 0; i < NUM_LEDS_KUGEL; i++)
    {
      ledsKugel[i] = CHSV(i - (j * 2), 255, 255);
    }
    FastLED.show();
    delay(5);
  }
}

void fillLEDs(CRGB color, uint8_t num, CRGB leds[])
{
  for (uint8_t i = 0; i < num; i++)
  {
    leds[i] = color;
  }
  FastLED.show();
}

void loop()
{
  EVERY_N_MILLISECONDS(50)
  {
    if (status == STATUS_RUNNING)
    {
      // FastLED.showColor(CRGB::Green);
      fillLEDs(CRGB::Green, NUM_LEDS_KUGEL, ledsKugel);
      fillLEDs(CRGB::Green, NUM_LEDS_STAND, ledsStand);
      runServo(freq, onDirChange);
    }
    else if (status == STATUS_STOPPED)
    {
      stopServo();

      fillLEDs(CRGB::Red, NUM_LEDS_KUGEL, ledsKugel);
      fillLEDs(CRGB::Red, NUM_LEDS_STAND, ledsStand);
    }
    else if (status == STATUS_MEASURING)
    {
      measureFrequency(5000, emaGyroZ);
    }
  }
}

/**
 * @brief gets data of MPU 6050
 *
 * @param _gyro gyroZ data
 * @param _accel accelX data
 */
void getIMUData(double *_gyro, double *_accel)
{
  sensors_event_t a, g, temp;
  mpu.getEvent(&a, &g, &temp);
  *_gyro = (emaGyroZAlpha * (g.gyro.z - 0.1)) + (1 - emaGyroZAlpha) * (*_gyro);
  *_accel = (emaAccelXAlpha * a.acceleration.x) + (1 - emaAccelXAlpha) * (*_accel);
}

/**
 * @brief check if given data is in range of 0
 *
 * @param data data to check
 * @return true
 * @return false
 */
bool checkIfZero(double data)
{
  return (data > -0.1 && data < 0.1);
}

/**
 * @brief Switch spin servo direction with desired frequency
 *
 * @param _freq switching frequency
 * @param _onDirChange callback on direction change
 */
void runServo(uint16_t _freq, void (*_onDirChange)(int8_t))
{
  static unsigned long previousTime = 0;

  if (_freq <= 0)
  {
    stopServo();
  }
  else if (millis() - previousTime >= _freq)
  {
    previousTime = millis();
    if (direction > 0)
    {
      servoSpin.write(127 - (SERVO_SPEED - 1));
    }
    else
    {
      servoSpin.write(127 + SERVO_SPEED);
    }
    direction *= -1;
    if (_onDirChange != nullptr)
    {
      _onDirChange(direction);
    }
  }
}

void stopServo()
{
  servoSpin.write(127);
}

/**
 * @brief Callback function for spin servo direction change, controls light flash
 *
 * @param dir direction of spin
 */
void onDirChange(int8_t dir)
{
  fillLEDs(CRGB::Purple, NUM_LEDS_KUGEL, ledsKugel);
  fillLEDs(CRGB::Purple, NUM_LEDS_STAND, ledsStand);
}

/**
 * @brief Measure perfect Frequency
 *
 * @param measureTime time in ms for how long it should get data
 * @param data imu data for measurement
 */
void measureFrequency(uint16_t measureTime, double data)
{
  unsigned long start = millis(); // 10000
  unsigned long measureDelay = 0;
  uint16_t _freq;
  double gyroData = 0;
  double accelData = 0;

  fillLEDs(CRGB::Black, NUM_LEDS_KUGEL, ledsKugel);
  fillLEDs(CRGB::Black, NUM_LEDS_STAND, ledsStand);
  stopServo();

  do
  {
    getIMUData(&gyroData, &accelData);

    // LED progress bar        12500 -  10000              10000 + 5000
    float progress = (float)(millis() - start) / (float)(measureTime);
    for (uint8_t i = NUM_LEDS_STAND - 1; i >= NUM_LEDS_STAND - float(NUM_LEDS_STAND * progress); i--)
    {
      ledsStand[i] = CRGB::Blue;
    }
    FastLED.show();

    if (checkIfZero(gyroData) && millis() - measureDelay >= 100)
    {
      // _freq = (0.1 * (millis() - measureDelay - 0.1)) + (1 - 0.1) * _freq;
      _freq = millis() - measureDelay;
      measureDelay = millis();
      pFreqCharacteristic->setValue(_freq);
      pFreqCharacteristic->notify();
    }
    delay(10);
  } while (start + measureTime > millis());

  status = STATUS_STOPPED;

  // flash led at the end
  for (uint8_t i = 0; i < 3; i++)
  {
    fillLEDs(CRGB::Blue, NUM_LEDS_KUGEL, ledsKugel);
    fillLEDs(CRGB::Blue, NUM_LEDS_STAND, ledsStand);
    delay(250);
    fillLEDs(CRGB::Black, NUM_LEDS_KUGEL, ledsKugel);
    fillLEDs(CRGB::Black, NUM_LEDS_STAND, ledsStand);
    delay(250);
  }

  pStatusCharacteristic->setValue(status);
  pStatusCharacteristic->notify();
  delay(10);
}
