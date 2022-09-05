//pages components
import Home from './pages/Home';
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
        <Home />
      </StyledContainer>
    </Router>
  );
}

export default App;
