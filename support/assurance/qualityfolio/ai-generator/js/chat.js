document.addEventListener("DOMContentLoaded", () => {
    // Inject HTML Structure
    const chatHTML = `
        <button id="chat-fab" title="Chat with Assistant">
            <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="icon icon-tabler icons-tabler-outline icon-tabler-message-chatbot">
              <path stroke="none" d="M0 0h24v24H0z" fill="none"/>
              <path d="M18 4a3 3 0 0 1 3 3v8a3 3 0 0 1 -3 3h-5l-5 3v-3h-2a3 3 0 0 1 -3 -3v-8a3 3 0 0 1 3 -3h12z" />
              <path d="M9.5 9h.01" />
              <path d="M14.5 9h.01" />
              <path d="M9.5 13a3.5 3.5 0 0 0 5 0" />
            </svg>
        </button>

        <div id="chat-container">
            <div class="chat-header">
                <span>AI Assistant</span>
                <button class="chat-close-btn">&times;</button>
            </div>
            <div class="chat-messages" id="chat-messages">
                <!-- Messages will appear here -->
                <div class="message assistant">
                    Hello! How can I help you today?
                </div>
            </div>
            <div class="chat-input-area">
                <textarea class="chat-input" id="chat-input" placeholder="Type a message..." rows="1"></textarea>
                <button class="chat-send-btn" id="chat-send-btn">
                    <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <line x1="22" y1="2" x2="11" y2="13"></line>
                        <polygon points="22 2 15 22 11 13 2 9 22 2"></polygon>
                    </svg>
                </button>
            </div>
        </div>
    `;

    const div = document.createElement('div');
    div.innerHTML = chatHTML;
    document.body.appendChild(div);

    // Elements
    const fab = document.getElementById('chat-fab');
    const container = document.getElementById('chat-container');
    const closeBtn = document.querySelector('.chat-close-btn');
    const sendBtn = document.getElementById('chat-send-btn');
    const input = document.getElementById('chat-input');
    const messagesContainer = document.getElementById('chat-messages');

    let isOpen = false;
    let isSending = false;
    const conversationHistory = []; // Local history for context

    // Functions
    function toggleChat() {
        isOpen = !isOpen;
        if (isOpen) {
            container.classList.add('show');
            input.focus();
        } else {
            container.classList.remove('show');
        }
    }

    function parseMarkdown(text) {
        if (!text) return '';
        return text
            .replace(/\*\*(.*?)\*\*/g, '<strong>$1</strong>')
            .replace(/\*(.*?)\*/g, '<em>$1</em>')
            .replace(/^- (.*)$/gm, '<li>$1</li>')
            .replace(/\[(.*?)\]\((.*?)\)/g, '<a href="$2" target="_blank">$1</a>')
            .replace(/\n\n/g, '<br><br>')
            .replace(/\n/g, '<br>');
    }

    function renderTable(data) {
        if (!Array.isArray(data) || data.length === 0) return '';

        const keys = Object.keys(data[0]);
        let html = '<div class="table-container"><table><thead><tr>';
        keys.forEach(key => html += `<th>${key}</th>`);
        html += '</tr></thead><tbody>';

        data.forEach(row => {
            html += '<tr>';
            keys.forEach(key => html += `<td>${row[key] || ''}</td>`);
            html += '</tr>';
        });

        html += '</tbody></table></div>';
        return html;
    }

    function addMessage(text, role, data = null) {
        const messageDiv = document.createElement('div');
        messageDiv.classList.add('message', role);

        let content = parseMarkdown(text);
        if (data) {
            content += renderTable(data);
        }

        messageDiv.innerHTML = content;
        messagesContainer.appendChild(messageDiv);
        scrollToBottom();

        // Add to history
        conversationHistory.push({ role, content: text });
    }

    function addTypingIndicator() {
        const indicator = document.createElement('div');
        indicator.id = 'typing-indicator';
        indicator.classList.add('message', 'assistant', 'typing-indicator');
        indicator.innerHTML = '<span></span><span></span><span></span>';
        messagesContainer.appendChild(indicator);
        scrollToBottom();
    }

    function removeTypingIndicator() {
        const indicator = document.getElementById('typing-indicator');
        if (indicator) indicator.remove();
    }

    function scrollToBottom() {
        messagesContainer.scrollTop = messagesContainer.scrollHeight;
    }

    async function sendMessage() {
        const text = input.value.trim();
        if (!text || isSending) return;

        isSending = true;
        input.value = '';
        input.disabled = true;
        sendBtn.disabled = true;

        addMessage(text, 'user');
        addTypingIndicator();

        try {
            const historyText = conversationHistory
                .map(msg => `${msg.role === 'user' ? 'User' : 'Assistant'}: ${msg.content}`)
                .join('\n');

            const formData = new URLSearchParams();
            formData.append('message', text);
            formData.append('history', historyText);

            const response = await fetch('/api/chat.sql', {
                method: 'POST',
                headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
                body: formData
            });

            if (!response.ok) {
                const errText = await response.text();
                throw new Error(`API Error ${response.status}`);
            }

            const data = await response.json();
            removeTypingIndicator();

            const payload = Array.isArray(data) ? (data[0]?.contents || data[0]) : (data.contents || data);

            if (payload && payload.response) {
                addMessage(payload.response, 'assistant', payload.data);
            } else {
                addMessage(`Debug: Invalid response.`, 'assistant');
            }

        } catch (error) {
            console.error('Chat Error:', error);
            removeTypingIndicator();
            addMessage(`Error: ${error.message || "Could not connect to AI service."}`, 'assistant');
        } finally {
            isSending = false;
            input.disabled = false;
            sendBtn.disabled = false;
            input.focus();
        }
    }

    // specific Event Listeners
    fab.addEventListener('click', toggleChat);
    closeBtn.addEventListener('click', toggleChat);

    sendBtn.addEventListener('click', sendMessage);

    input.addEventListener('keydown', (e) => {
        if (e.key === 'Enter' && !e.shiftKey) {
            e.preventDefault();
            sendMessage();
        }
    });

    // Auto-resize textarea
    input.addEventListener('input', function () {
        this.style.height = 'auto';
        this.style.height = (this.scrollHeight) + 'px';
        if (this.value === '') this.style.height = '44px';
    });
});
