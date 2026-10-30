-- =========================================================
-- 출석부 DB 실습
-- MySQL 8.0 / Workbench
-- 위에서부터 차례대로 실행
-- 한 문장: Ctrl + Enter    블록 전체: Ctrl + Shift + Enter
-- =========================================================


-- ---------------------------------------------------------
-- 1. DB 만들기
-- ---------------------------------------------------------
DROP DATABASE IF EXISTS attend_db;

CREATE DATABASE attend_db
  DEFAULT CHARACTER SET utf8mb4
  DEFAULT COLLATE utf8mb4_general_ci;

USE attend_db;


-- ---------------------------------------------------------
-- 2. 테이블 만들기 (부모 테이블 먼저)
-- ---------------------------------------------------------
CREATE TABLE students (
  student_id INT AUTO_INCREMENT PRIMARY KEY,
  student_no VARCHAR(20) NOT NULL UNIQUE,
  name       VARCHAR(30) NOT NULL,
  grade      TINYINT     NOT NULL,
  department VARCHAR(30) NOT NULL,
  phone      VARCHAR(20)
);

CREATE TABLE courses (
  course_id   INT AUTO_INCREMENT PRIMARY KEY,
  course_name VARCHAR(60) NOT NULL,
  professor   VARCHAR(30),
  credit      TINYINT NOT NULL
);

CREATE TABLE enrollments (
  enrollment_id INT AUTO_INCREMENT PRIMARY KEY,
  student_id    INT NOT NULL,
  course_id     INT NOT NULL,
  UNIQUE KEY uk_enroll (student_id, course_id),
  FOREIGN KEY (student_id) REFERENCES students(student_id),
  FOREIGN KEY (course_id)  REFERENCES courses(course_id)
);

CREATE TABLE class_sessions (
  session_id   INT AUTO_INCREMENT PRIMARY KEY,
  course_id    INT NOT NULL,
  session_date DATE NOT NULL,
  week_no      TINYINT NOT NULL,
  UNIQUE KEY uk_session (course_id, session_date),
  FOREIGN KEY (course_id) REFERENCES courses(course_id)
);

CREATE TABLE attendance (
  attendance_id INT AUTO_INCREMENT PRIMARY KEY,
  session_id INT NOT NULL,
  student_id INT NOT NULL,
  status ENUM('출석','지각','결석','공결') NOT NULL DEFAULT '출석',
  memo       VARCHAR(100),
  checked_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uk_attend (session_id, student_id),
  FOREIGN KEY (session_id) REFERENCES class_sessions(session_id),
  FOREIGN KEY (student_id) REFERENCES students(student_id)
);

SHOW TABLES;
DESC attendance;


-- ---------------------------------------------------------
-- 3. 데이터 넣기
-- ---------------------------------------------------------
-- 학생 6명 (정다솜은 아직 수강신청 안 함)
INSERT INTO students (student_no, name, grade, department, phone) VALUES
  ('20260001', '김하늘', 1, '문헌정보', '010-1111-0001'),
  ('20260002', '이바다', 1, '문헌정보', NULL),
  ('20250003', '박구름', 2, '문헌정보', '010-1111-0003'),
  ('20250004', '최나무', 2, '경영',     '010-1111-0004'),
  ('20260005', '정다솜', 1, '경영',     NULL),
  ('20240006', '강한별', 3, '문헌정보', '010-1111-0006');

-- 과목 3개 (독서치료는 신청자 없음)
INSERT INTO courses (course_name, professor, credit) VALUES
  ('DB설계',   '김교수', 3),
  ('자료조직', '이교수', 3),
  ('독서치료', '박교수', 2);

-- 수강신청
INSERT INTO enrollments (student_id, course_id) VALUES
  (1, 1), (2, 1), (3, 1), (4, 1), (6, 1),
  (1, 2), (3, 2), (6, 2);

-- 수업 회차 (1~4: DB설계, 5~6: 자료조직)
INSERT INTO class_sessions (course_id, session_date, week_no) VALUES
  (1, '2026-09-01', 1), (1, '2026-09-08', 2),
  (1, '2026-09-15', 3), (1, '2026-09-22', 4),
  (2, '2026-09-02', 1), (2, '2026-09-09', 2);

-- 출석 (최나무 4주차는 아직 체크 전)
INSERT INTO attendance (session_id, student_id, status, memo) VALUES
  (1, 1, '출석', NULL), (1, 2, '지각', '버스 지연'), (1, 3, '출석', NULL), (1, 4, '결석', NULL), (1, 6, '출석', NULL),
  (2, 1, '출석', NULL), (2, 2, '결석', NULL), (2, 3, '공결', '학과 행사'), (2, 4, '출석', NULL), (2, 6, '지각', NULL),
  (3, 1, '출석', NULL), (3, 2, '결석', NULL), (3, 3, '출석', NULL), (3, 4, '출석', NULL), (3, 6, '출석', NULL),
  (4, 1, '지각', NULL), (4, 2, '결석', NULL), (4, 3, '출석', NULL), (4, 6, '출석', NULL),
  (5, 1, '출석', NULL), (5, 3, '지각', NULL), (5, 6, '출석', NULL),
  (6, 1, '출석', NULL), (6, 3, '출석', NULL), (6, 6, '결석', NULL);

-- 6 / 3 / 8 / 6 / 25 나오면 OK
SELECT (SELECT COUNT(*) FROM students)       AS students,
       (SELECT COUNT(*) FROM courses)        AS courses,
       (SELECT COUNT(*) FROM enrollments)    AS enrollments,
       (SELECT COUNT(*) FROM class_sessions) AS sessions,
       (SELECT COUNT(*) FROM attendance)     AS attendance;


-- ---------------------------------------------------------
-- 4. 조회
-- ---------------------------------------------------------
SELECT * FROM students;

-- 1학년만, 이름순
SELECT name, grade, department
FROM students
WHERE grade = 1
ORDER BY name;

-- 연락처 없는 학생
SELECT name, phone FROM students WHERE phone IS NULL;

-- 이름에 '다'
SELECT name FROM students WHERE name LIKE '%다%';

-- 2, 3학년 (학년 높은 순)
SELECT name, grade FROM students
WHERE grade IN (2, 3)
ORDER BY grade DESC, name;

-- 9/8 ~ 9/15 수업
SELECT session_id, course_id, session_date
FROM class_sessions
WHERE session_date BETWEEN '2026-09-08' AND '2026-09-15'
ORDER BY session_date;


-- ---------------------------------------------------------
-- 5. 수정
-- ---------------------------------------------------------
-- 이바다 2주차: 결석 -> 공결 (진단서)
-- 먼저 찾아보고
SELECT attendance_id, session_id, student_id, status, memo
FROM attendance
WHERE session_id = 2 AND student_id = 2;

-- 고치고
UPDATE attendance
SET status = '공결', memo = '진단서 제출'
WHERE attendance_id = 7;

-- 다시 확인
SELECT attendance_id, status, memo FROM attendance WHERE attendance_id = 7;


-- ---------------------------------------------------------
-- 6. 삭제
-- ---------------------------------------------------------
-- 정다솜 출석을 잘못 넣음 (DB설계 수강생 아님)
INSERT INTO attendance (session_id, student_id, status) VALUES (1, 5, '출석');

SELECT attendance_id, session_id, student_id, status
FROM attendance
WHERE student_id = 5;

DELETE FROM attendance
WHERE session_id = 1 AND student_id = 5;

SELECT COUNT(*) AS 남은기록 FROM attendance WHERE student_id = 5;

-- 트랜잭션: 지웠다가 되돌리기
START TRANSACTION;

DELETE FROM attendance WHERE session_id = 4;

SELECT COUNT(*) AS 개수 FROM attendance WHERE session_id = 4;

ROLLBACK;

SELECT COUNT(*) AS 개수 FROM attendance WHERE session_id = 4;


-- ---------------------------------------------------------
-- 7. INNER JOIN
-- ---------------------------------------------------------
-- 1주차 출석에 이름 붙이기
SELECT a.session_id, s.name, a.status
FROM attendance a
INNER JOIN students s ON a.student_id = s.student_id
WHERE a.session_id = 1
ORDER BY s.student_id;


-- ---------------------------------------------------------
-- 8. OUTER JOIN (LEFT, RIGHT, FULL)
-- ---------------------------------------------------------
-- 모든 학생 + 듣는 과목 (정다솜 NULL)
SELECT s.name, c.course_name
FROM students s
LEFT JOIN enrollments e ON s.student_id = e.student_id
LEFT JOIN courses c     ON e.course_id  = c.course_id
ORDER BY s.student_id, c.course_id;

-- 모든 과목 + 수강생 수 (독서치료 0)
SELECT c.course_name, COUNT(e.student_id) AS 수강생
FROM enrollments e
RIGHT JOIN courses c ON e.course_id = c.course_id
GROUP BY c.course_id, c.course_name
ORDER BY c.course_id;

-- FULL: MySQL에는 없어서 LEFT + RIGHT를 UNION
SELECT s.name, c.course_name
FROM students s
LEFT JOIN enrollments e ON s.student_id = e.student_id
LEFT JOIN courses c     ON e.course_id  = c.course_id
UNION
SELECT s.name, c.course_name
FROM students s
RIGHT JOIN enrollments e ON s.student_id = e.student_id
RIGHT JOIN courses c     ON e.course_id  = c.course_id
ORDER BY 1, 2;


-- ---------------------------------------------------------
-- 9. CROSS JOIN, SELF JOIN
-- ---------------------------------------------------------
-- 모든 조합: 6 x 3
SELECT COUNT(*) AS 조합수 FROM students CROSS JOIN courses;

-- 같은 학과 학생끼리 짝 짓기 (같은 테이블 두 번)
SELECT a.name AS 학생1, b.name AS 학생2, a.department
FROM students a
JOIN students b
  ON a.department = b.department
 AND a.student_id < b.student_id
ORDER BY a.student_id, b.student_id;


-- ---------------------------------------------------------
-- 10. 여러 테이블 JOIN
-- ---------------------------------------------------------
-- 이바다 출석부
SELECT c.course_name, cs.week_no, cs.session_date, a.status
FROM attendance a
JOIN students s        ON a.student_id = s.student_id
JOIN class_sessions cs ON a.session_id = cs.session_id
JOIN courses c         ON cs.course_id = c.course_id
WHERE s.name = '이바다'
ORDER BY cs.week_no;

-- 체크 안 된 칸 찾기
SELECT s.name, c.course_name, cs.week_no
FROM enrollments e
JOIN students s        ON e.student_id = s.student_id
JOIN courses c         ON e.course_id  = c.course_id
JOIN class_sessions cs ON cs.course_id = e.course_id
LEFT JOIN attendance a ON a.session_id = cs.session_id
                      AND a.student_id = e.student_id
WHERE a.attendance_id IS NULL;


-- ---------------------------------------------------------
-- 11. 출석 상태 -> 점수 (CASE)
-- ---------------------------------------------------------
-- 출석·공결 1, 지각 0.5, 결석 0
SELECT s.name, a.status,
       CASE
         WHEN a.status IN ('출석', '공결') THEN 1.0
         WHEN a.status = '지각'            THEN 0.5
         ELSE 0
       END AS 점수
FROM attendance a
JOIN students s ON a.student_id = s.student_id
WHERE a.session_id = 2
ORDER BY s.student_id;


-- ---------------------------------------------------------
-- 12. 출석 점수 계산 (DB설계, 20점 만점)
-- ---------------------------------------------------------
-- 기록 기준
SELECT s.name,
       COUNT(*) AS 기록수,
       SUM(CASE WHEN a.status IN ('출석', '공결') THEN 1.0
                WHEN a.status = '지각' THEN 0.5
                ELSE 0 END) AS 점수합,
       ROUND(SUM(CASE WHEN a.status IN ('출석', '공결') THEN 1.0
                      WHEN a.status = '지각' THEN 0.5
                      ELSE 0 END) / COUNT(*) * 20, 1) AS 출석점수
FROM attendance a
JOIN students s        ON a.student_id = s.student_id
JOIN class_sessions cs ON a.session_id = cs.session_id
WHERE cs.course_id = 1
GROUP BY s.student_id, s.name
ORDER BY 출석점수 DESC, s.name;

-- 수업 횟수 기준 (체크 안 된 회차는 0점)
SELECT s.name,
       SUM(CASE WHEN a.status IN ('출석', '공결') THEN 1.0
                WHEN a.status = '지각' THEN 0.5
                ELSE 0 END) AS 점수합,
       (SELECT COUNT(*) FROM class_sessions WHERE course_id = 1) AS 수업수,
       ROUND(SUM(CASE WHEN a.status IN ('출석', '공결') THEN 1.0
                      WHEN a.status = '지각' THEN 0.5
                      ELSE 0 END)
             / (SELECT COUNT(*) FROM class_sessions WHERE course_id = 1) * 20, 1) AS 출석점수
FROM attendance a
JOIN students s        ON a.student_id = s.student_id
JOIN class_sessions cs ON a.session_id = cs.session_id
WHERE cs.course_id = 1
GROUP BY s.student_id, s.name
ORDER BY 출석점수 DESC, s.name;


-- ---------------------------------------------------------
-- 13. 그룹별 조회
-- ---------------------------------------------------------
-- 상태별 개수
SELECT status, COUNT(*) AS 개수
FROM attendance
GROUP BY status
ORDER BY status;

-- 학과별 학생 수
SELECT department, COUNT(*) AS 학생수
FROM students
GROUP BY department
ORDER BY 학생수 DESC;

-- 과목별 · 학생별 출석점수
SELECT c.course_name, s.name,
       ROUND(SUM(CASE WHEN a.status IN ('출석', '공결') THEN 1.0
                      WHEN a.status = '지각' THEN 0.5
                      ELSE 0 END) / COUNT(*) * 20, 1) AS 출석점수
FROM attendance a
JOIN students s        ON a.student_id = s.student_id
JOIN class_sessions cs ON a.session_id = cs.session_id
JOIN courses c         ON cs.course_id = c.course_id
GROUP BY c.course_id, c.course_name, s.student_id, s.name
ORDER BY c.course_id, s.student_id;

-- 15점 미만만
SELECT c.course_name, s.name,
       ROUND(SUM(CASE WHEN a.status IN ('출석', '공결') THEN 1.0
                      WHEN a.status = '지각' THEN 0.5
                      ELSE 0 END) / COUNT(*) * 20, 1) AS 출석점수
FROM attendance a
JOIN students s        ON a.student_id = s.student_id
JOIN class_sessions cs ON a.session_id = cs.session_id
JOIN courses c         ON cs.course_id = c.course_id
GROUP BY c.course_id, c.course_name, s.student_id, s.name
HAVING 출석점수 < 15
ORDER BY 출석점수;
