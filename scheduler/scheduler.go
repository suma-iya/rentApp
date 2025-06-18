package scheduler

import (
	"go-rent/handlers"
	"time"
)

// StartScheduler starts all scheduled tasks
func StartScheduler() {
	// Start monthly notification scheduler
	go scheduleMonthlyNotifications()
}

// scheduleMonthlyNotifications schedules the monthly notification task
func scheduleMonthlyNotifications() {
	for {
		// Get current time in Bangladesh timezone
		now := time.Now().In(time.FixedZone("BDT", 6*60*60))
		
		// Calculate time until next 5th of the month
		nextRun := time.Date(now.Year(), now.Month(), 5, 0, 0, 0, 0, now.Location())
		if now.Day() >= 5 {
			// If we're past the 5th, schedule for next month
			nextRun = nextRun.AddDate(0, 1, 0)
		}

		// Calculate duration until next run
		duration := nextRun.Sub(now)
		
		// Sleep until next run
		time.Sleep(duration)
		
		// Send notifications
		handlers.SendMonthlyNotifications()
	}
} 