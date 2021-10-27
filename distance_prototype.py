#!/usr/bin/env python3

# *****************************************
# PiFire Prototype Distance Interface Library
# *****************************************
#
# Description: This library supports getting the hopper level from stored value
#
# *****************************************

import random
from common import WriteLog

class HopperLevel:

	def __init__(self, empty=22, full=4):
		self.empty = empty # Empty is greater than distance measured for empty
		self.full = full # Full is less than or equal to the minimum full distance.
		if self.empty <= self.full:
			event = 'ERROR: Invalid Hopper Level Configuration Empty Level <= Full Level (forcing defaults)'
			WriteLog(event)
			# Set defaults that are valid
			self.empty = 22
			self.full = 4
		self.SetLevel()
	
	def SetLevel(self, level=100):
		# Do nothing
		return()

	def GetLevel(self):
		return random.randint(10, 100)