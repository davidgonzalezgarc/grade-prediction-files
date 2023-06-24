USE grade_prediction;
DELIMITER //
DROP PROCEDURE IF EXISTS Dataset //
CREATE PROCEDURE Dataset(
    IN course_id_param VARCHAR(99),       		-- course id
    IN school_year_param smallint,    			-- only this year
    IN grade_item_position_param smallint,		-- up to this position (including)
    IN student_id_param VARCHAR(99)				-- only this student id
    )
    DETERMINISTIC
    SQL SECURITY INVOKER
BEGIN
	DECLARE position_counter INT UNSIGNED DEFAULT 0;
	DECLARE positions LONGTEXT DEFAULT "";
    DECLARE percentages LONGTEXT DEFAULT "";
    DECLARE grades LONGTEXT DEFAULT "";
    
    WHILE position_counter <= grade_item_position_param DO
		IF position_counter != 0 
			THEN SET positions = CONCAT(positions, ", ");
		END IF;
		SET positions = CONCAT(positions, (
			SELECT GROUP_CONCAT(DISTINCT
				CONCAT(
					"SUM(CASE WHEN `grade_item_id`='", `grade_item_id`, "' THEN `position` END) AS `grade_item_", `grade_item_id`, "_position`"
				)
			)
			FROM grade g 
				INNER JOIN grade_item gi ON gi.id = g.grade_item_id
			WHERE gi.position = position_counter AND gi.course_id = course_id_param
		));
        SET position_counter = position_counter + 1;
    END WHILE;
    
    SET position_counter = 0;
    WHILE position_counter <= grade_item_position_param DO
		IF position_counter != 0 
			THEN SET percentages = CONCAT(percentages, ", ");
		END IF;
		SET percentages = CONCAT(percentages, (
			SELECT GROUP_CONCAT(DISTINCT
				CONCAT(
					"SUM(CASE WHEN `grade_item_id`='", `grade_item_id`, "' THEN `percentage` END) AS `grade_item_", `grade_item_id`, "_percentage`"
				)
			)
			FROM grade g 
				INNER JOIN grade_item gi ON gi.id = g.grade_item_id
			WHERE gi.position = position_counter AND gi.course_id = course_id_param
		));
        SET position_counter = position_counter + 1;
    END WHILE;
	
	SET position_counter = 0;
    WHILE position_counter <= grade_item_position_param DO
		IF position_counter != 0 
			THEN SET grades = CONCAT(grades, ", ");
		END IF;
		SET grades = CONCAT(grades, (
			SELECT GROUP_CONCAT(DISTINCT
				CONCAT(
					"SUM(CASE WHEN `grade_item_id`='", `grade_item_id`, "' THEN `grade` END) AS `grade_item_", `grade_item_id`, "_grade`"
				)
			)
			FROM grade g 
				INNER JOIN grade_item gi ON gi.id = g.grade_item_id
			WHERE gi.position = position_counter AND gi.course_id = course_id_param
		));
        SET position_counter = position_counter + 1;
    END WHILE;
    
    IF student_id_param IS NOT NULL THEN
		SET @where_student_is = CONCAT(" AND g.student_id = '", student_id_param, "'");
	ELSE
		SET @where_student_is = '';
	END IF;
    
    IF school_year_param IS NOT NULL THEN
		SET @where_school_year_is = CONCAT(" AND sc.school_year = ", school_year_param);
	ELSE
		SET @where_school_year_is = '';
	END IF;
    
	SET @sql = CONCAT("SELECT si.*, sc.*, ", positions, ", ", percentages, ", ", grades,
	" FROM grade g", 
	" INNER JOIN grade_item gi ON g.grade_item_id = gi.id", 
	" INNER JOIN course c ON c.id = gi.course_id", 
	" INNER JOIN student_information si ON si.id = g.student_id", 
	" INNER JOIN student_course sc ON sc.course_id = c.id AND sc.student_id = si.id", 
	" WHERE c.id = '", course_id_param, "'",
	@where_student_is,
    @where_school_year_is,
	" GROUP BY si.id, sc.school_year");

	PREPARE stmt FROM @sql;
	EXECUTE stmt;
	DEALLOCATE PREPARE stmt;
END;
//
DELIMITER ;