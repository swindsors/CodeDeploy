import streamlit as st
import math
from calculator import calculate_basic, calculate_scientific, CalculatorError

def main():
    st.title("🧮 Simple Calculator2")
    st.write("A simple calculator built with Streamlit")
    
    # Create tabs for different calculator modes
    tab1, tab2 = st.tabs(["Basic Calculator", "Scientific Calculator"])
    
    with tab1:
        st.header("Basic Operations")
        
        # Input fields
        col1, col2, col3 = st.columns([2, 1, 2])
        
        with col1:
            num1 = st.number_input("First Number", value=0.0, format="%.2f")
        
        with col2:
            operation = st.selectbox(
                "Operation",
                ["+", "-", "×", "÷"],
                index=0
            )
        
        with col3:
            num2 = st.number_input("Second Number", value=0.0, format="%.2f")
        
        # Calculate button
        if st.button("Calculate", type="primary"):
            success, result = calculate_basic(num1, operation, num2)
            
            if success:
                st.success(f"Result: {num1} {operation} {num2} = {result}")
            else:
                st.error(f"Error: {result}")
    
    with tab2:
        st.header("Scientific Operations")
        
        col1, col2 = st.columns(2)
        
        with col1:
            st.subheader("Single Number Operations  1")
            number = st.number_input("Enter Number", value=0.0, format="%.4f", key="sci_num")
            
            sci_operation = st.selectbox(
                "Choose Operation",
                ["Square Root", "Square", "Cube", "Sine", "Cosine", "Tangent", "Natural Log", "Log Base 10"]
            )
            
            if st.button("Calculate Scientific", type="primary"):
                success, result = calculate_scientific(sci_operation, number)
                
                if success:
                    if sci_operation == "Square Root":
                        st.success(f"√{number} = {result}")
                    elif sci_operation == "Square":
                        st.success(f"{number}² = {result}")
                    elif sci_operation == "Cube":
                        st.success(f"{number}³ = {result}")
                    elif sci_operation == "Sine":
                        st.success(f"sin({number}°) = {result}")
                    elif sci_operation == "Cosine":
                        st.success(f"cos({number}°) = {result}")
                    elif sci_operation == "Tangent":
                        st.success(f"tan({number}°) = {result}")
                    elif sci_operation == "Natural Log":
                        st.success(f"ln({number}) = {result}")
                    elif sci_operation == "Log Base 10":
                        st.success(f"log₁₀({number}) = {result}")
                else:
                    st.error(f"Error: {result}")
        
        with col2:
            st.subheader("Power Operations")
            base = st.number_input("Base", value=2.0, format="%.2f")
            exponent = st.number_input("Exponent", value=2.0, format="%.2f")
            
            if st.button("Calculate Power"):
                success, result = calculate_scientific("Power", None, base, exponent)
                
                if success:
                    st.success(f"{base}^{exponent} = {result}")
                else:
                    st.error(f"Error: {result}")
    
    # History section
    st.markdown("---")
    st.subheader("Calculator Features")
    
    col1, col2, col3 = st.columns(3)
    
    with col1:
        st.info("✅ Basic arithmetic operations")
        st.info("✅ Scientific functions")
    
    with col2:
        st.info("✅ Error handling")
        st.info("✅ User-friendly interface")
    
    with col3:
        st.info("✅ Multiple calculation modes")
        st.info("✅ Real-time results")

if __name__ == "__main__":
    main()
