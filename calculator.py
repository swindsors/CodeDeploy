"""
Calculator business logic module.
Contains pure functions for mathematical operations that can be easily tested.
"""
import math


class CalculatorError(Exception):
    """Custom exception for calculator errors."""
    pass


def add(a, b):
    """Add two numbers."""
    return a + b


def subtract(a, b):
    """Subtract b from a."""
    return a - b


def multiply(a, b):
    """Multiply two numbers."""
    return a * b


def divide(a, b):
    """Divide a by b."""
    if b == 0:
        raise CalculatorError("Division by zero is not allowed!")
    return a / b


def square_root(number):
    """Calculate square root of a number."""
    if number < 0:
        raise CalculatorError("Cannot calculate square root of negative number!")
    return math.sqrt(number)


def square(number):
    """Calculate square of a number."""
    return number ** 2


def cube(number):
    """Calculate cube of a number."""
    return number ** 3


def power(base, exponent):
    """Calculate base raised to the power of exponent."""
    try:
        return base ** exponent
    except OverflowError:
        raise CalculatorError("Result too large to calculate!")


def sine(degrees):
    """Calculate sine of angle in degrees."""
    return math.sin(math.radians(degrees))


def cosine(degrees):
    """Calculate cosine of angle in degrees."""
    return math.cos(math.radians(degrees))


def tangent(degrees):
    """Calculate tangent of angle in degrees."""
    return math.tan(math.radians(degrees))


def natural_log(number):
    """Calculate natural logarithm of a number."""
    if number <= 0:
        raise CalculatorError("Natural log is only defined for positive numbers!")
    return math.log(number)


def log_base_10(number):
    """Calculate base-10 logarithm of a number."""
    if number <= 0:
        raise CalculatorError("Logarithm is only defined for positive numbers!")
    return math.log10(number)


# Operation mapping for easy lookup
BASIC_OPERATIONS = {
    "+": add,
    "-": subtract,
    "×": multiply,
    "÷": divide
}


def calculate_basic(num1, operation, num2):
    """
    Perform basic calculation with error handling.
    
    Args:
        num1: First number
        operation: Operation symbol (+, -, ×, ÷)
        num2: Second number
    
    Returns:
        tuple: (success: bool, result: float or error_message: str)
    """
    try:
        if operation not in BASIC_OPERATIONS:
            return False, f"Unknown operation: {operation}"
        
        operation_func = BASIC_OPERATIONS[operation]
        result = operation_func(num1, num2)
        return True, result
    
    except CalculatorError as e:
        return False, str(e)
    except Exception as e:
        return False, f"An error occurred: {str(e)}"


def calculate_scientific(operation, number, base=None, exponent=None):
    """
    Perform scientific calculation with error handling.
    
    Args:
        operation: Scientific operation name
        number: Input number
        base: Base for power operations (optional)
        exponent: Exponent for power operations (optional)
    
    Returns:
        tuple: (success: bool, result: float or error_message: str)
    """
    try:
        if operation == "Square Root":
            result = square_root(number)
        elif operation == "Square":
            result = square(number)
        elif operation == "Cube":
            result = cube(number)
        elif operation == "Sine":
            result = sine(number)
        elif operation == "Cosine":
            result = cosine(number)
        elif operation == "Tangent":
            result = tangent(number)
        elif operation == "Natural Log":
            result = natural_log(number)
        elif operation == "Log Base 10":
            result = log_base_10(number)
        elif operation == "Power" and base is not None and exponent is not None:
            result = power(base, exponent)
        else:
            return False, f"Unknown scientific operation: {operation}"
        
        return True, result
    
    except CalculatorError as e:
        return False, str(e)
    except Exception as e:
        return False, f"An error occurred: {str(e)}"
