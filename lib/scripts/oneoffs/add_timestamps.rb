date = DateTime.now

Service.update_all(created_at: date, updated_at: date)
