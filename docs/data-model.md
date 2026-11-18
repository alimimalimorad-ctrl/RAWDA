# Data model overview

- tenants: nursery organizations.
- profiles: user profile, keyed to auth.users.
- memberships: user-to-tenant relationship and role.
- classrooms: tenant-owned classrooms.
- children: child identity and enrollment profile.
- parent_children: authorized parent/guardian relationship.
- teachers: staff record associated with profile.
- classroom_teachers: teacher assignments.
- enrollments: child placement in a classroom for a period.
- subjects: learning areas.
- books: learning library metadata and private storage path.
- curriculum_units: curriculum hierarchy.
- daily_lessons: what a class studied on a date.
- skills: age/level learning skills.
- assessments: teacher observations against a skill.
- attendance: daily attendance events.
- announcements: tenant announcements.
- subscriptions: tenant plan and status.

Assessment values are descriptive mastery stages, not a clinical or developmental diagnosis.
Use observations and evidence, and avoid ranking children against one another.
