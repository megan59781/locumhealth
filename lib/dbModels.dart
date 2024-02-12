
class Worker {
  final int worker_id;
  final String worker_fname;
  final String worker_sname;
  final DateTime worker_bday;
  final String worker_email;
  final String worker_location;

  Worker({
    required this.worker_id,
    required this.worker_fname,
    required this.worker_sname,
    required this.worker_bday,
    required this.worker_email,
    required this.worker_location,
  });

  Worker.fromMap(Map<String, dynamic> res)
      : worker_id = res["worker_id"],
        worker_fname = res["worker_fname"],
        worker_sname = res["worker_sname"],
        worker_bday = DateTime.parse(res["worker_bday"]),
        worker_email = res["worker_email"],
        worker_location = res["worker_location"];

  Map<String, Object?> toMap() {
    return {
      'worker_id': worker_id,
      'worker_fname': worker_fname,
      'worker_sname': worker_sname,
      'worker_bday': worker_bday.toIso8601String(),
      'worker_email': worker_email,
      'worker_location': worker_location,
    };
  }
}


class Availability {
  final int available_id;
  final int worker_id; // fk to worker table
  final String week_day;
  final DateTime day_start_time;
  final DateTime day_end_time;
  final int miles;

  Availability({
    required this.available_id,
    required this.worker_id,
    required this.week_day,
    required this.day_start_time,
    required this.day_end_time,
    required this.miles,
  });

  Availability.fromMap(Map<String, dynamic> res)
      : available_id = res["available_id"],
        worker_id = res["worker_id"],
        week_day = res["week_day"],
        day_start_time = DateTime.parse(res["day_start_time"]),
        day_end_time = DateTime.parse(res["day_end_time"]),
        miles = res["miles"];

  Map<String, Object?> toMap() {
    return {
      'available_id': available_id,
      'worker_id': worker_id,
      'week_day': week_day,
      'day_start_time': day_start_time.toIso8601String(),
      'day_end_time': day_end_time.toIso8601String(),
      'miles': miles,
    };
  }
}


class Company {
  final int company_id;
  final String company_name;
  final String company_email;
  final String company_location;

  Company({
    required this.company_id,
    required this.company_name,
    required this.company_email,
    required this.company_location,
  });

  Company.fromMap(Map<String, dynamic> res)
      : company_id = res["company_id"],
        company_name = res["company_name"],
        company_email = res["company_email"],
        company_location = res["company_location"];

  Map<String, Object?> toMap() {
    return {
      'company_id': company_id,
      'company_name': company_name,
      'company_email': company_email,
      'company_location': company_location,
    };
  }
}


class Job {
  final int job_id;
  final int company_id; //fk to company table
  final String job_status;
  final DateTime job_date;
  final DateTime job_start_time;
  final DateTime job_end_time;
  final String job_location;

  Job({
    required this.job_id,
    required this.company_id,
    required this.job_status,
    required this.job_date,
    required this.job_start_time,
    required this.job_end_time,
    required this.job_location,
  });

  Job.fromMap(Map<String, dynamic> res)
      : job_id = res["job_id"],
        company_id = res["company_id"],
        job_status = res["job_status"],
        job_date = DateTime.parse(res["job_date"]),
        job_start_time = DateTime.parse(res["job_start_time"]),
        job_end_time = DateTime.parse(res["job_end_time"]),
        job_location = res["job_location"];

  Map<String, Object?> toMap() {
    return {
      'job_id': job_id,
      'company_id': company_id,
      'job_status': job_status,
      'job_date': job_date.toIso8601String(),
      'job_start_time': job_start_time.toIso8601String(),
      'job_end_time': job_end_time.toIso8601String(),
      'job_location': job_location,
    };
  }
}

class AssignedJobs {
  final int assign_id;
  final int job_id; // fk to job table
  final int company_id; // fk to company table
  final int worker_id; // fk to worker table
  final bool worker_complete;
  final bool company_complete;

  AssignedJobs({
    required this.assign_id,
    required this.job_id,
    required this.company_id,
    required this.worker_id,
    required this.worker_complete,
    required this.company_complete,
  });

  AssignedJobs.fromMap(Map<String, dynamic> res)
      : assign_id = res["assign_id"],
        job_id = res["job_id"],
        company_id = res["company_id"],
        worker_id = res["worker_id"],
        worker_complete = res["worker_complete"],
        company_complete = res["company_complete"];

  Map<String, Object?> toMap() {
    return {
      'assign_id': assign_id,
      'job_id': job_id,
      'company_id': company_id,
      'worker_id': worker_id,
      'worker_complete': worker_complete,
      'company_complete': company_complete,
    };
  }
}