"""
Comprehensive test suite for the calculator module.
Tests all mathematical operations and error handling.
"""
import pytest
import math
from calculator import (
    add, subtract, multiply, divide, square_root, square, cube, power,
    sine, cosine, tangent, natural_log, log_base_10,
    calculate_basic, calculate_scientific, CalculatorError
)


class TestBasicOperations:
    """Test basic arithmetic operations."""
    
    def test_addition(self):
        """Test addition operation - including the requested 2 + 2 = 4."""
        assert add(2, 2) == 4  # Your requested test case!
        assert add(0, 0) == 0
        assert add(-1, 1) == 0
        assert add(10, 5) == 15
        assert add(-5, -3) == -8
        assert add(2.5, 3.7) == pytest.approx(6.2)
    
    def test_subtraction(self):
        """Test subtraction operation."""
        assert subtract(5, 3) == 2
        assert subtract(10, 10) == 0
        assert subtract(0, 5) == -5
        assert subtract(-3, -7) == 4
        assert subtract(7.5, 2.3) == pytest.approx(5.2)
    
    def test_multiplication(self):
        """Test multiplication operation."""
        assert multiply(3, 4) == 12
        assert multiply(0, 100) == 0
        assert multiply(-2, 5) == -10
        assert multiply(-3, -4) == 12
        assert multiply(2.5, 4) == 10.0
    
    def test_division(self):
        """Test division operation."""
        assert divide(10, 2) == 5
        assert divide(15, 3) == 5
        assert divide(-12, 4) == -3
        assert divide(-15, -3) == 5
        assert divide(7.5, 2.5) == 3.0
    
    def test_division_by_zero(self):
        """Test that division by zero raises appropriate error."""
        with pytest.raises(CalculatorError, match="Division by zero is not allowed!"):
            divide(5, 0)
        
        with pytest.raises(CalculatorError, match="Division by zero is not allowed!"):
            divide(-10, 0)


class TestScientificOperations:
    """Test scientific mathematical operations."""
    
    def test_square_root(self):
        """Test square root operation."""
        assert square_root(4) == 2
        assert square_root(9) == 3
        assert square_root(0) == 0
        assert square_root(2) == pytest.approx(1.414, rel=1e-3)
        assert square_root(100) == 10
    
    def test_square_root_negative(self):
        """Test that square root of negative number raises error."""
        with pytest.raises(CalculatorError, match="Cannot calculate square root of negative number!"):
            square_root(-4)
    
    def test_square(self):
        """Test square operation."""
        assert square(3) == 9
        assert square(0) == 0
        assert square(-4) == 16
        assert square(2.5) == 6.25
    
    def test_cube(self):
        """Test cube operation."""
        assert cube(2) == 8
        assert cube(3) == 27
        assert cube(0) == 0
        assert cube(-2) == -8
    
    def test_power(self):
        """Test power operation."""
        assert power(2, 3) == 8
        assert power(5, 2) == 25
        assert power(10, 0) == 1
        assert power(2, -1) == 0.5
        assert power(4, 0.5) == 2.0
    
    def test_trigonometric_functions(self):
        """Test trigonometric functions."""
        # Test common angles
        assert sine(0) == pytest.approx(0, abs=1e-10)
        assert sine(90) == pytest.approx(1, abs=1e-10)
        assert cosine(0) == pytest.approx(1, abs=1e-10)
        assert cosine(90) == pytest.approx(0, abs=1e-10)
        assert tangent(0) == pytest.approx(0, abs=1e-10)
        assert tangent(45) == pytest.approx(1, abs=1e-10)
    
    def test_logarithmic_functions(self):
        """Test logarithmic functions."""
        assert natural_log(1) == pytest.approx(0, abs=1e-10)
        assert natural_log(math.e) == pytest.approx(1, abs=1e-10)
        assert log_base_10(1) == pytest.approx(0, abs=1e-10)
        assert log_base_10(10) == pytest.approx(1, abs=1e-10)
        assert log_base_10(100) == pytest.approx(2, abs=1e-10)
    
    def test_logarithm_invalid_input(self):
        """Test that logarithms of non-positive numbers raise errors."""
        with pytest.raises(CalculatorError, match="Natural log is only defined for positive numbers!"):
            natural_log(0)
        
        with pytest.raises(CalculatorError, match="Natural log is only defined for positive numbers!"):
            natural_log(-5)
        
        with pytest.raises(CalculatorError, match="Logarithm is only defined for positive numbers!"):
            log_base_10(0)
        
        with pytest.raises(CalculatorError, match="Logarithm is only defined for positive numbers!"):
            log_base_10(-10)


class TestCalculateBasicFunction:
    """Test the calculate_basic wrapper function."""
    
    def test_successful_calculations(self):
        """Test successful basic calculations."""
        success, result = calculate_basic(2, "+", 2)
        assert success is True
        assert result == 4  # Your requested test case!
        
        success, result = calculate_basic(10, "-", 3)
        assert success is True
        assert result == 7
        
        success, result = calculate_basic(4, "×", 5)
        assert success is True
        assert result == 20
        
        success, result = calculate_basic(15, "÷", 3)
        assert success is True
        assert result == 5
    
    def test_division_by_zero_handling(self):
        """Test division by zero error handling."""
        success, error_msg = calculate_basic(10, "÷", 0)
        assert success is False
        assert "Division by zero is not allowed!" in error_msg
    
    def test_invalid_operation(self):
        """Test invalid operation handling."""
        success, error_msg = calculate_basic(5, "%", 2)
        assert success is False
        assert "Unknown operation: %" in error_msg


class TestCalculateScientificFunction:
    """Test the calculate_scientific wrapper function."""
    
    def test_successful_scientific_calculations(self):
        """Test successful scientific calculations."""
        success, result = calculate_scientific("Square Root", 16)
        assert success is True
        assert result == 4
        
        success, result = calculate_scientific("Square", 5)
        assert success is True
        assert result == 25
        
        success, result = calculate_scientific("Cube", 3)
        assert success is True
        assert result == 27
    
    def test_scientific_error_handling(self):
        """Test scientific calculation error handling."""
        success, error_msg = calculate_scientific("Square Root", -4)
        assert success is False
        assert "Cannot calculate square root of negative number!" in error_msg
        
        success, error_msg = calculate_scientific("Natural Log", 0)
        assert success is False
        assert "Natural log is only defined for positive numbers!" in error_msg
    
    def test_invalid_scientific_operation(self):
        """Test invalid scientific operation handling."""
        success, error_msg = calculate_scientific("Invalid Operation", 5)
        assert success is False
        assert "Unknown scientific operation: Invalid Operation" in error_msg


class TestEdgeCases:
    """Test edge cases and boundary conditions."""
    
    def test_very_large_numbers(self):
        """Test calculations with very large numbers."""
        large_num = 1e10
        assert add(large_num, large_num) == 2e10
        assert multiply(large_num, 2) == 2e10
    
    def test_very_small_numbers(self):
        """Test calculations with very small numbers."""
        small_num = 1e-10
        assert add(small_num, small_num) == pytest.approx(2e-10)
        assert multiply(small_num, 2) == pytest.approx(2e-10)
    
    def test_floating_point_precision(self):
        """Test floating point precision issues."""
        # Use pytest.approx for floating point comparisons
        result = add(0.1, 0.2)
        assert result == pytest.approx(0.3)
        
        result = divide(1, 3)
        assert multiply(result, 3) == pytest.approx(1.0)


class TestIntegrationScenarios:
    """Test realistic calculator usage scenarios."""
    
    def test_calculator_workflow(self):
        """Test a typical calculator workflow."""
        # Start with 2 + 2 = 4 (your requested test)
        success, result = calculate_basic(2, "+", 2)
        assert success is True
        assert result == 4
        
        # Then square the result: 4² = 16
        success, result = calculate_scientific("Square", result)
        assert success is True
        assert result == 16
        
        # Then take square root: √16 = 4
        success, result = calculate_scientific("Square Root", result)
        assert success is True
        assert result == 4
        
        # Finally divide by 2: 4 ÷ 2 = 2
        success, final_result = calculate_basic(result, "÷", 2)
        assert success is True
        assert final_result == 2
    
    def test_error_recovery(self):
        """Test that errors don't break subsequent calculations."""
        # First, cause an error
        success, error_msg = calculate_basic(5, "÷", 0)
        assert success is False
        
        # Then verify normal calculations still work
        success, result = calculate_basic(2, "+", 2)
        assert success is True
        assert result == 4


if __name__ == "__main__":
    # Run tests when script is executed directly
    pytest.main([__file__, "-v"])
