let currentData = null;
let currentEditingJob = null;

// Initialize app
document.addEventListener('DOMContentLoaded', function() {
    console.log('DOM loaded, initializing...');
    initializeEventListeners();
});

// Event listeners
function initializeEventListeners() {
    console.log('Setting up event listeners...');
    
    // Close button
    const closeBtn = document.getElementById('closeBtn');
    if (closeBtn) {
        closeBtn.addEventListener('click', function(e) {
            e.preventDefault();
            console.log('Close button clicked');
            closeMenu();
        });
    }
    
    // Navigation tabs
    document.querySelectorAll('.nav-tab').forEach(tab => {
        tab.addEventListener('click', function(e) {
            e.preventDefault();
            console.log('Tab clicked:', this.dataset.tab);
            switchTab(this.dataset.tab);
        });
    });
    
    // Create job form
    const createJobForm = document.getElementById('createJobForm');
    if (createJobForm) {
        createJobForm.addEventListener('submit', function(e) {
            e.preventDefault();
            console.log('Create job form submitted');
            handleCreateJob(e);
        });
    }
    
    // ESC key listener
    document.addEventListener('keydown', function(e) {
        if (e.key === 'Escape') {
            console.log('ESC key pressed');
            closeMenu();
        }
    });
    
    console.log('Event listeners set up successfully');
}

// NUI Message handler
window.addEventListener('message', function(event) {
    const data = event.data;
    console.log('NUI Message received:', data);
    
    switch(data.action) {
        case 'openMenu':
            console.log('Opening menu...');
            document.getElementById('app').classList.remove('hidden');
            break;
            
        case 'closeMenu':
            console.log('Closing menu...');
            document.getElementById('app').classList.add('hidden');
            break;
            
        case 'receiveData':
            console.log('Received data:', data.data);
            currentData = data.data;
            updateInterface();
            break;
    }
});

// Update interface with received data
function updateInterface() {
    console.log('Updating interface with data...');
    if (!currentData) return;
    
    updateStatistics();
    updateJobsList();
    updateCategorySelects();
}

// Update statistics
function updateStatistics() {
    if (!currentData.statistics) return;
    
    const stats = currentData.statistics;
    console.log('Updating statistics:', stats);
    
    safeUpdateElement('totalJobs', stats.totalJobs || 0);
    safeUpdateElement('activeJobs', stats.activeJobs || 0);
    safeUpdateElement('inactiveJobs', stats.inactiveJobs || 0);
    safeUpdateElement('totalCompletions', stats.totalCompletions || 0);
    
    // Additional stats
    const jobs = currentData.jobs || [];
    const avgPayment = jobs.length > 0 ? 
        Math.round(jobs.reduce((sum, job) => sum + (job.payment || 0), 0) / jobs.length) : 0;
    
    safeUpdateElement('avgPayment', `$${avgPayment.toLocaleString()}`);
    
    const totalRevenue = jobs.reduce((sum, job) => sum + (job.payment || 0), 0) * stats.totalCompletions;
    safeUpdateElement('totalRevenue', `$${totalRevenue.toLocaleString()}`);
    
    // Most popular category
    const categoryCount = {};
    jobs.forEach(job => {
        categoryCount[job.category] = (categoryCount[job.category] || 0) + 1;
    });
    
    const popularCategory = Object.keys(categoryCount).reduce((a, b) => 
        categoryCount[a] > categoryCount[b] ? a : b, 'None');
    
    safeUpdateElement('popularCategory', popularCategory.charAt(0).toUpperCase() + popularCategory.slice(1));
}

// Safe element update
function safeUpdateElement(id, value) {
    const element = document.getElementById(id);
    if (element) {
        element.textContent = value;
    }
}

// Update jobs list
function updateJobsList() {
    const jobsList = document.getElementById('jobsList');
    if (!jobsList) return;
    
    const jobs = currentData.jobs || [];
    console.log('Updating jobs list with', jobs.length, 'jobs');
    
    if (jobs.length === 0) {
        jobsList.innerHTML = '<div class="no-jobs" style="text-align: center; color: #b0b0b0; padding: 2rem;">No jobs found. Create your first job!</div>';
        return;
    }
    
    jobsList.innerHTML = jobs.map(job => createJobCard(job)).join('');
    
    // Add event listeners to job cards
    setTimeout(() => {
        addJobCardListeners();
    }, 100);
}

// Add event listeners to job cards
function addJobCardListeners() {
    const jobs = currentData.jobs || [];
    
    document.querySelectorAll('.job-card').forEach(card => {
        const jobId = parseInt(card.dataset.jobId);
        const job = jobs.find(j => j.id === jobId);
        
        if (job) {
            // Edit button
            const editBtn = card.querySelector('.btn-edit');
            if (editBtn) {
                editBtn.addEventListener('click', function(e) {
                    e.preventDefault();
                    e.stopPropagation();
                    console.log('Edit button clicked for job:', jobId);
                    openEditModal(job);
                });
            }
            
            // Delete button
            const deleteBtn = card.querySelector('.btn-delete');
            if (deleteBtn) {
                deleteBtn.addEventListener('click', function(e) {
                    e.preventDefault();
                    e.stopPropagation();
                    console.log('Delete button clicked for job:', jobId);
                    deleteJob(jobId);
                });
            }
            
            // Toggle button
            const toggleBtn = card.querySelector('.btn-toggle');
            if (toggleBtn) {
                toggleBtn.addEventListener('click', function(e) {
                    e.preventDefault();
                    e.stopPropagation();
                    console.log('Toggle button clicked for job:', jobId);
                    toggleJobStatus(jobId, !job.is_active);
                });
            }
        }
    });
}

// Create job card HTML
function createJobCard(job) {
    const categories = currentData.categories || [];
    const category = categories.find(c => c.name === job.category) || 
                    { color: '#666', label: job.category };
    
    return `
        <div class="job-card" data-job-id="${job.id}">
            <div class="job-header">
                <div>
                    <div class="job-title">${job.job_label || 'Sin nombre'}</div>
                    <div class="job-category" style="background: ${category.color};">
                        ${category.label || job.category}
                    </div>
                </div>
                <div class="job-status">
                    <div class="status-dot ${job.is_active ? 'active' : 'inactive'}"></div>
                    <span>${job.is_active ? 'Active' : 'Inactive'}</span>
                </div>
            </div>
            
            <div class="job-description">
                ${job.description || 'No description provided.'}
            </div>
            
            <div class="job-stats">
                <div class="job-stat">
                    <div class="job-stat-value">$${(job.payment || 0).toLocaleString()}</div>
                    <div class="job-stat-label">Payment</div>
                </div>
                <div class="job-stat">
                    <div class="job-stat-value">Lv.${job.required_level || 1}</div>
                    <div class="job-stat-label">Required Level</div>
                </div>
                <div class="job-stat">
                    <div class="job-stat-value">${job.max_players || 4}</div>
                    <div class="job-stat-label">Max Players</div>
                </div>
                <div class="job-stat">
                    <div class="job-stat-value">${Math.round((job.cooldown || 0) / 60)}m</div>
                    <div class="job-stat-label">Cooldown</div>
                </div>
            </div>
            
            <div class="job-actions">
                <button class="btn btn-small btn-secondary btn-edit" type="button">
                    <i class="fas fa-edit"></i> Edit
                </button>
                <button class="btn btn-small ${job.is_active ? 'btn-warning' : 'btn-success'} btn-toggle" type="button">
                    <i class="fas fa-${job.is_active ? 'pause' : 'play'}"></i> 
                    ${job.is_active ? 'Disable' : 'Enable'}
                </button>
                <button class="btn btn-small btn-danger btn-delete" type="button">
                    <i class="fas fa-trash"></i> Delete
                </button>
            </div>
        </div>
    `;
}

// Update category selects
function updateCategorySelects() {
    const selects = [
        document.getElementById('jobCategory'),
        document.getElementById('categoryFilter')
    ];
    
    const categories = currentData.categories || [];
    
    selects.forEach(select => {
        if (!select) return;
        
        // Clear existing options (except filter)
        if (select.id === 'categoryFilter') {
            select.innerHTML = '<option value="">All Categories</option>';
        } else {
            select.innerHTML = '';
        }
        
        // Add category options
        categories.forEach(category => {
            const option = document.createElement('option');
            option.value = category.name;
            option.textContent = category.label;
            select.appendChild(option);
        });
    });
}

// Switch tabs
function switchTab(tabName) {
    console.log('Switching to tab:', tabName);
    
    // Update navigation
    document.querySelectorAll('.nav-tab').forEach(tab => {
        tab.classList.remove('active');
    });
    const activeTab = document.querySelector(`[data-tab="${tabName}"]`);
    if (activeTab) activeTab.classList.add('active');
    
    // Update content
    document.querySelectorAll('.tab-content').forEach(content => {
        content.classList.remove('active');
    });
    const activeContent = document.getElementById(tabName);
    if (activeContent) activeContent.classList.add('active');
}

// Handle create job form
function handleCreateJob(e) {
    e.preventDefault();
    console.log('Handling create job...');
    
    const formData = new FormData(e.target);
    const jobData = {};
    
    // Convert form data to object
    for (let [key, value] of formData.entries()) {
        if (value.trim() !== '') {
            if (['payment', 'required_level', 'max_players', 'cooldown', 'blip_sprite', 'blip_color'].includes(key)) {
                jobData[key] = parseInt(value) || 0;
            } else {
                jobData[key] = value.trim();
            }
        }
    }
    
    console.log('Sending job data:', jobData);
    
    // Send to server
    sendNUICallback('createJob', jobData);
    
    // Clear form
    clearForm();
    
    // Switch to jobs tab
    switchTab('jobs');
}

// Delete job with better error handling
function deleteJob(jobId) {
    console.log('Attempting to delete job:', jobId);
    
    if (confirm('Are you sure you want to delete this job? This action cannot be undone.')) {
        console.log('User confirmed deletion of job:', jobId);
        sendNUICallback('deleteJob', { id: jobId });
    } else {
        console.log('User cancelled deletion');
    }
}

// Toggle job status
function toggleJobStatus(jobId, isActive) {
    console.log('Toggling job status:', jobId, 'to', isActive);
    sendNUICallback('toggleJobStatus', { id: jobId, isActive: isActive });
}

// Open edit modal (placeholder)
function openEditModal(job) {
    console.log('Edit modal would open for job:', job);
    alert('Edit functionality coming soon!');
}

// Clear form
function clearForm() {
    const form = document.getElementById('createJobForm');
    if (form) {
        form.reset();
        console.log('Form cleared');
    }
}

// Send NUI callback with better error handling
function sendNUICallback(endpoint, data = {}) {
    console.log(`Sending ${endpoint} with data:`, data);
    
    try {
        fetch(`https://jobs/${endpoint}`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(data)
        }).then(response => {
            console.log(`${endpoint} response status:`, response.status);
            if (!response.ok) {
                throw new Error(`HTTP error! status: ${response.status}`);
            }
            return response.text();
        }).then(text => {
            console.log(`${endpoint} response:`, text);
        }).catch(error => {
            console.error(`Error sending ${endpoint}:`, error);
        });
    } catch (error) {
        console.error(`Failed to send ${endpoint}:`, error);
    }
}

// Close menu
function closeMenu() {
    console.log('Closing menu from JavaScript...');
    sendNUICallback('closeMenu');
}

// VIP MENU SYSTEM

let vipData = null;

// Initialize VIP event listeners
function initializeVipEventListeners() {
    console.log('Setting up VIP event listeners...');
    
    // VIP close button
    const vipCloseBtn = document.getElementById('closeVipBtn');
    if (vipCloseBtn) {
        vipCloseBtn.addEventListener('click', function(e) {
            e.preventDefault();
            console.log('VIP close button clicked');
            closeVipMenu();
        });
    }
    
    // Claim reward buttons
    document.querySelectorAll('.claim-btn').forEach(btn => {
        btn.addEventListener('click', function(e) {
            e.preventDefault();
            const rewardType = this.dataset.reward;
            console.log('Claim reward clicked:', rewardType);
            claimReward(rewardType);
        });
    });
    
    // ESC key listener for VIP menu
    document.addEventListener('keydown', function(e) {
        if (e.key === 'Escape') {
            const vipApp = document.getElementById('vipApp');
            if (vipApp && !vipApp.classList.contains('hidden')) {
                console.log('ESC key pressed - closing VIP menu');
                closeVipMenu();
            }
        }
    });
}

// Call this on DOM load
document.addEventListener('DOMContentLoaded', function() {
    console.log('DOM loaded, initializing...');
    initializeEventListeners();
    initializeVipEventListeners();
});

// NUI message handlers
window.addEventListener('message', function(event) {
    const data = event.data;
    console.log('Received message:', data);
    
    switch (data.action) {
        case 'openMenu':
            openMenu();
            break;
        case 'closeMenu':
            hideMenu();
            break;
        case 'receiveData':
            currentData = data.data;
            populateUI(data.data);
            break;
        case 'openVipMenu':
            openVipMenu();
            break;
        case 'closeVipMenu':
            hideVipMenu();
            break;
        case 'receiveVipData':
            vipData = data.data;
            populateVipUI(data.data);
            break;
        case 'rewardClaimed':
            handleRewardClaimed(data.rewardType);
            break;
        default:
            console.log('Unknown action:', data.action);
    }
});

// Open VIP menu
function openVipMenu() {
    console.log('Opening VIP menu...');
    const vipApp = document.getElementById('vipApp');
    if (vipApp) {
        vipApp.classList.remove('hidden');
    }
}

// Hide VIP menu
function hideVipMenu() {
    console.log('Hiding VIP menu...');
    const vipApp = document.getElementById('vipApp');
    if (vipApp) {
        vipApp.classList.add('hidden');
    }
}

// Close VIP menu
function closeVipMenu() {
    console.log('Closing VIP menu from JavaScript...');
    sendNUICallback('closeVipMenu');
}

// Populate VIP UI with data
function populateVipUI(data) {
    console.log('Populating VIP UI with data:', data);
    
    if (!data) return;
    
    // Update reward labels
    if (data.rewards) {
        if (data.rewards.money) {
            const moneyLabel = document.getElementById('moneyRewardLabel');
            if (moneyLabel) moneyLabel.textContent = data.rewards.money.label;
        }
        
        if (data.rewards.weapon) {
            const weaponLabel = document.getElementById('weaponRewardLabel');
            if (weaponLabel) weaponLabel.textContent = data.rewards.weapon.label;
        }
        
        if (data.rewards.vehicle) {
            const vehicleLabel = document.getElementById('vehicleRewardLabel');
            if (vehicleLabel) vehicleLabel.textContent = data.rewards.vehicle.label;
        }
    }
    
    // Update claimed status
    if (data.claimed) {
        Object.keys(data.claimed).forEach(rewardType => {
            const card = document.querySelector(`[data-reward="${rewardType}"]`);
            if (card) {
                if (data.claimed[rewardType]) {
                    card.classList.add('claimed');
                    const claimedBadge = card.querySelector('.claimed-badge');
                    if (claimedBadge) claimedBadge.classList.remove('hidden');
                } else {
                    card.classList.remove('claimed');
                    const claimedBadge = card.querySelector('.claimed-badge');
                    if (claimedBadge) claimedBadge.classList.add('hidden');
                }
            }
        });
    }
}

// Claim reward
function claimReward(rewardType) {
    console.log('Claiming reward:', rewardType);
    sendNUICallback('claimReward', { rewardType: rewardType });
}

// Handle reward claimed
function handleRewardClaimed(rewardType) {
    console.log('Reward claimed:', rewardType);
    
    const card = document.querySelector(`[data-reward="${rewardType}"]`);
    if (card) {
        card.classList.add('claimed');
        const claimedBadge = card.querySelector('.claimed-badge');
        if (claimedBadge) claimedBadge.classList.remove('hidden');
    }
    
    // Update vipData if it exists
    if (vipData && vipData.claimed) {
        vipData.claimed[rewardType] = true;
    }
}