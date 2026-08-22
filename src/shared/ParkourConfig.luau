return {
	Walking = {
		Speed = 16,
	},

	Sprinting = {
		Speed = 30,
	},

	Sliding = {
		Duration = 2,
		Boost = 40,
		Deceleration = 60,
		MinSpeed = 20,
	},

	Vaulting = {
		CheckDistance = 4,
		MaxHeight = 4,
		HorizontalSpeedMultiplier = 1.3,
		VerticalSpeedMultiplier = 1,

		TopClearanceHeight = 2.5,
		TopProbeInset = 0.05,

		ClearanceDistance = 6,
		ClearanceCheckLength = 2,

		LandingCheckDistance = 5,
		GroundCheckDistance = 5,

		InitialVerticalSpeed = 12,
		VerticalAcceleration = 60,
		FinishVerticalSpeed = -10,

		ForceMultiplier = 1000,
	},

	LedgeGrab = {
		Cooldown = 1,
		FrontProbeHeight = 2,
		CheckDistance = 3,

		TopProbeHeight = 4,
		TopProbeInset = 0.1,
		MaxHeight = 3,

		WallOffset = 0.7,
		VerticalOffset = 1.5,

		AnimationFadeTime = 0.15,
	},
}
