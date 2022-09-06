import {useState} from 'react';
import {useField} from 'formik';
import{
    StyledTextInput,
    StyledLabel,
    StyledIcon
}from "./../components/Styles";

//password eye icon
import { FiEye, FiEyeOff } from 'react-icons/fi';

export const TextInput = ({icon, ...props}) => {
    const [field, meta] = useField(props);
    const [show, setShow] = useState(false);

    return(
        <div style={{position: "relative"}}>
            <StyledLabel htmlFor={props.name}>
                {props.label}
            </StyledLabel>
            <StyledTextInput 
                {...field}
                {...props}
            />
            <StyledIcon>
                {icon}
            </StyledIcon>
            {
                props.type === "password" &&
                <StyledIcon onClick={() => setShow(!show)} right>
                    {show && <FiEye/>}
                    {!show && <FiEyeOff/>}
                </StyledIcon>
            }
        </div>
    )
}