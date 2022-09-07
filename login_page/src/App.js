//pages components
import Home from './pages/Home';
import Login from './pages/Login';
import Signup from './pages/Signup';
//styled components
import { StyledContainer } from './components/Styles';

import {
  BrowserRouter as Router,
  Switch, Route
} from 'react-router-dom';

function App() {
  return (
    <Router>
      <StyledContainer>
        <Signup />
      </StyledContainer>
    </Router>
  );
}

export default App;
