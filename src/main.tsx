import React from 'react';
import ReactDOM from 'react-dom/client';
import App from './App';
import './index.css';

async function enableMocking() {
  if (import.meta.env.DEV) {
    const { worker } = await import('./mocks/browser');
    return worker.start({
      onUnhandledRequest: 'bypass',
    });
  }
}

function renderApp() {
  const rootElement = document.getElementById('root');
  if (!rootElement) {
    throw new Error('Root element not found. Ensure there is a <div id="root"> in index.html.');
  }
  ReactDOM.createRoot(rootElement).render(
    <React.StrictMode>
      <App />
    </React.StrictMode>,
  );
}

enableMocking()
  .then(() => {
    renderApp();
  })
  .catch((err) => {
    console.error('Failed to initialize MSW:', err);
    renderApp();
  });
