#!/usr/bin/env python3

# *****************************************
# PiFire hcsr04 Interface Library
# *****************************************
#
# Description: This library supports getting the hopper level from the distance sensor
#  NOTE: This library hasn't been tested with real hardware yet and is provided for testing.  
#
# Library dependancy installation instructions:
#  sudo pip3 install hcsr04sensor
#
# *****************************************

# *****************************************
# Imported Libraries
# *****************************************

from hcsr04sensor import sensor
import time 

class HopperLevel:

	def __init__(self, empty=22, full=4):
		self.empty = empty # Empty is greater than 30cm distance measured
		self.full = full # Full is less than or equal to the minimum full distance.
		if self.empty <= self.full:
			event = 'ERROR: Invalid Hopper Level Configuration Empty Level <= Full Level (forcing defaults)'
			WriteLog(event)
			# Set defaults that are valid
			self.empty = 22
			self.full = 4

		# (NOTE: This is a 5V device and must be connected to 5V VCC)
		self.trig_pin = 23 # Modify to match design
		# (NOTE: This pin (echo_pin) must have a resistor divider to reduce the voltage to tolerable levels)
		# (Details: https://www.linuxnorth.org/hcsr04sensor/)
		self.echo_pin = 27 # Modify to match design 
		
		# Default values
		# unit = 'metric'
		# temperature = 20 (room temp in Celsius)

		#  Create a distance reading with the hcsr04 sensor module
		self.ultrasonic = sensor.Measurement(self.trig_pin, self.echo_pin)

	def SetLevel(self, level=100):
		# Do nothing
		return()

	def GetLevel(self):
		AvgDist = self.ultrasonic.raw_distance()  # Average Distance in cm

		# If Average Distance is less than the full distance, we are at 100%
		if AvgDist <= self.full: 
			level = 100
		
		# If Average Distance is less than the empty distance, calculate percentage
		elif AvgDist <= self.empty:
			capacity = self.empty - self.full
			adjusted_ratio = (self.empty / capacity) * 100 
			level = adjusted_ratio * (1 - (AvgDist / self.empty))  
		# If Average Distance is higher than empty distance, report 0 level
		else:
			level = 0

		return(int(level))