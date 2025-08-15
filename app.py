import streamlit as st

def main():
    st.title("Hello World Streamlit App")
    st.write("Welcome to your first Streamlit app deployed on AWS!")
    
    st.header("About this app- deployed 2")
    st.write("This is a simple hello world application built with Streamlit and deployed using AWS CodePipeline and CodeDeploy.")
    
    # Add some interactive elements
    name = st.text_input("Enter your name:")
    if name:
        st.write(f"Hello, {name}! 👋")
    
    # Add a button
    if st.button("Click me!"):
        st.balloons()
        st.success("Thanks for clicking!")

if __name__ == "__main__":
    main()
