class CourseController {
  constructor() {
    this.courses = [
      {
        id: 'alphabet_basics',
        title: 'Alphabet Basics',
        description: 'Learn to trace basic letters',
        icon: '🔤',
        requiredXP: 0,
        exercises: [
          {
            id: 'trace_a',
            type: 'trace',
            title: 'Trace Letter A',
            description: 'Draw the letter A on the canvas',
            data: { letter: 'A' },
            baseXP: 10
          },
          {
            id: 'trace_b',
            type: 'trace',
            title: 'Trace Letter B',
            description: 'Draw the letter B on the canvas',
            data: { letter: 'B' },
            baseXP: 15
          },
          {
            id: 'trace_c',
            type: 'trace',
            title: 'Trace Letter C',
            description: 'Draw the letter C on the canvas',
            data: { letter: 'C' },
            baseXP: 12
          }
        ],
        unlocked: true
      },
      {
        id: 'counting_fun',
        title: 'Counting Fun',
        description: 'Practice counting objects',
        icon: '🔢',
        requiredXP: 50,
        exercises: [
          {
            id: 'count_apples',
            type: 'count',
            title: 'Count Apples',
            description: 'How many apples do you see?',
            data: { imageId: 'apples' },
            baseXP: 20
          },
          {
            id: 'count_balls',
            type: 'count',
            title: 'Count Balls',
            description: 'How many balls do you see?',
            data: { imageId: 'balls' },
            baseXP: 25
          },
          {
            id: 'count_cars',
            type: 'count',
            title: 'Count Cars',
            description: 'How many cars do you see?',
            data: { imageId: 'cars' },
            baseXP: 18
          }
        ],
        unlocked: false
      },
      {
        id: 'rhythm_master',
        title: 'Rhythm Master',
        description: 'Tap along with the beat',
        icon: '🎵',
        requiredXP: 100,
        exercises: [
          {
            id: 'rhythm_basic',
            type: 'rhythm',
            title: 'Basic Rhythm',
            description: 'Tap along with the basic beat',
            data: { bpm: 120, pattern: [0, 500, 1000, 1500] },
            baseXP: 25
          },
          {
            id: 'rhythm_medium',
            type: 'rhythm',
            title: 'Medium Rhythm',
            description: 'Tap along with a faster beat',
            data: { bpm: 140, pattern: [0, 428, 857, 1285] },
            baseXP: 30
          },
          {
            id: 'rhythm_advanced',
            type: 'rhythm',
            title: 'Advanced Rhythm',
            description: 'Master the complex rhythm',
            data: { bpm: 160, pattern: [0, 375, 750, 1125, 1500] },
            baseXP: 35
          }
        ],
        unlocked: false
      },
      {
        id: 'advanced_tracing',
        title: 'Advanced Tracing',
        description: 'Master complex letter formations',
        icon: '✍️',
        requiredXP: 200,
        exercises: [
          {
            id: 'trace_m',
            type: 'trace',
            title: 'Trace Letter M',
            description: 'Draw the complex letter M',
            data: { letter: 'M' },
            baseXP: 20
          },
          {
            id: 'trace_w',
            type: 'trace',
            title: 'Trace Letter W',
            description: 'Draw the complex letter W',
            data: { letter: 'W' },
            baseXP: 20
          },
          {
            id: 'trace_q',
            type: 'trace',
            title: 'Trace Letter Q',
            description: 'Draw the complex letter Q',
            data: { letter: 'Q' },
            baseXP: 22
          }
        ],
        unlocked: false
      },
      {
        id: 'number_mastery',
        title: 'Number Mastery',
        description: 'Advanced counting challenges',
        icon: '🔢',
        requiredXP: 300,
        exercises: [
          {
            id: 'count_mixed',
            type: 'count',
            title: 'Mixed Objects',
            description: 'Count different types of objects',
            data: { imageId: 'mixed' },
            baseXP: 30
          },
          {
            id: 'count_pattern',
            type: 'count',
            title: 'Pattern Counting',
            description: 'Count objects in a pattern',
            data: { imageId: 'pattern' },
            baseXP: 35
          }
        ],
        unlocked: false
      }
    ];
  }

  async getCourses() {
    // In a real implementation, this would fetch from database
    // For now, return the static courses
    return this.courses;
  }

  async getCourseById(courseId) {
    return this.courses.find(course => course.id === courseId);
  }

  async getExercisesForCourse(courseId) {
    const course = await this.getCourseById(courseId);
    return course ? course.exercises : [];
  }

  async getExerciseById(exerciseId) {
    for (const course of this.courses) {
      const exercise = course.exercises.find(ex => ex.id === exerciseId);
      if (exercise) {
        return exercise;
      }
    }
    return null;
  }

  async unlockCourse(courseId, userXP) {
    const course = await this.getCourseById(courseId);
    if (course && userXP >= course.requiredXP) {
      course.unlocked = true;
      return true;
    }
    return false;
  }

  async getUnlockedCourses(userXP) {
    return this.courses.filter(course => 
      course.requiredXP <= userXP || course.unlocked
    );
  }
}

module.exports = CourseController;