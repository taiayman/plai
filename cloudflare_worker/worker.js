export default {
    async fetch(request, env) {
        const corsHeaders = {
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Methods": "GET, POST, PUT, PATCH, DELETE, OPTIONS",
            "Access-Control-Allow-Headers": "Content-Type, App-Secret, Authorization, Admin-Auth",
            "Access-Control-Max-Age": "86400",
        };

        // Handle CORS preflight for ALL requests
        if (request.method === "OPTIONS") {
            return new Response(null, {
                status: 204,
                headers: corsHeaders
            });
        }

        try {
            const url = new URL(request.url);
            const path = url.pathname;

            // Validate App Secret for all requests
            const appSecret = request.headers.get("App-Secret");
            if (appSecret !== "MySecretPassword123") {
                return new Response(JSON.stringify({ error: "Unauthorized" }), {
                    status: 401,
                    headers: { "Content-Type": "application/json", ...corsHeaders }
                });
            }

            // Route: Generate Game (Gemini)
            // Support both /generate and root / (for backward compatibility if needed)
            if ((path === "/generate" || path === "/") && request.method === "POST") {
                return await handleGeminiGeneration(request, env, corsHeaders);
            }

            // Route: Tenor GIF - Featured
            if (path === "/tenor/featured" && request.method === "GET") {
                return await handleTenorFeatured(env, corsHeaders);
            }

            // Route: Tenor GIF - Search
            if (path === "/tenor/search" && request.method === "GET") {
                const query = url.searchParams.get("q") || "";
                return await handleTenorSearch(env, corsHeaders, query);
            }

            // Route: Auth (Anonymous Login)
            if (path === "/auth/guest" && request.method === "POST") {
                return await handleGuestLogin(env, corsHeaders);
            }

            // Route: Auth (Email Sign Up)
            if (path === "/auth/signup" && request.method === "POST") {
                return await handleEmailSignUp(request, env, corsHeaders);
            }

            // Route: Auth (Email Sign In)
            if (path === "/auth/signin" && request.method === "POST") {
                return await handleEmailSignIn(request, env, corsHeaders);
            }

            // Route: Create Game
            if (path === "/games" && request.method === "POST") {
                return await handleCreateGame(request, env, corsHeaders);
            }

            // Route: Get Games Feed
            if (path === "/games" && request.method === "GET") {
                return await handleGetGames(env, corsHeaders);
            }

            // Route: Update User
            if (path.startsWith("/users/") && request.method === "PATCH") {
                const userId = path.split("/")[2];
                return await handleUpdateUser(request, env, corsHeaders, userId);
            }

            // Route: Get User Profile
            if (path.startsWith("/users/") && request.method === "GET") {
                const userId = path.split("/")[2];
                return await handleGetUser(env, corsHeaders, userId);
            }

            // Route: Game Actions (Like/View)
            // Pattern: /games/:id/like or /games/:id/view
            if (path.startsWith("/games/") && request.method === "POST") {
                const parts = path.split("/");
                const gameId = parts[2];
                const action = parts[3]; // 'like', 'view', or 'comments'

                if (action === "like" || action === "view") {
                    return await handleGameAction(env, corsHeaders, gameId, action);
                }
                if (action === "comments") {
                    // Check if it's a comment like/unlike: /games/:gameId/comments/:commentId/like or /unlike
                    const commentId = parts[4];
                    const commentAction = parts[5];
                    if (commentId && commentAction === "like") {
                        return await handleCommentLike(request, env, corsHeaders, gameId, commentId);
                    }
                    if (commentId && commentAction === "unlike") {
                        return await handleCommentUnlike(request, env, corsHeaders, gameId, commentId);
                    }
                    // Otherwise it's posting a new comment
                    return await handlePostComment(request, env, corsHeaders, gameId);
                }
            }

            // Route: Get Comments for a game
            if (path.match(/\/games\/.+\/comments$/) && request.method === "GET") {
                const gameId = path.split("/")[2];
                return await handleGetComments(env, corsHeaders, gameId);
            }

            // Route: Get Notifications (mock for now - would require proper notification system)
            if (path === "/notifications" && request.method === "GET") {
                return await handleGetNotifications(corsHeaders);
            }

            // ==========================================
            // ADMIN ROUTES
            // ==========================================

            // Admin: Get all users
            if (path === "/admin/users" && request.method === "GET") {
                return await handleAdminGetUsers(env, corsHeaders);
            }

            // Admin: Ban user
            if (path.match(/\/admin\/users\/.+\/ban/) && request.method === "POST") {
                const userId = path.split("/")[3];
                return await handleAdminBanUser(env, corsHeaders, userId, true);
            }

            // Admin: Unban user
            if (path.match(/\/admin\/users\/.+\/unban/) && request.method === "POST") {
                const userId = path.split("/")[3];
                return await handleAdminBanUser(env, corsHeaders, userId, false);
            }

            // Admin: Get all games (with more data)
            if (path === "/admin/games" && request.method === "GET") {
                return await handleAdminGetGames(env, corsHeaders);
            }

            // Admin: Delete game
            if (path.startsWith("/admin/games/") && request.method === "DELETE") {
                const gameId = path.split("/")[3];
                return await handleAdminDeleteGame(env, corsHeaders, gameId);
            }

            // Admin: Feature game
            if (path.match(/\/admin\/games\/.+\/feature/) && request.method === "PATCH") {
                const gameId = path.split("/")[3];
                return await handleAdminFeatureGame(request, env, corsHeaders, gameId);
            }

            // Admin: Flag game
            if (path.match(/\/admin\/games\/.+\/flag/) && request.method === "PATCH") {
                const gameId = path.split("/")[3];
                return await handleAdminFlagGame(request, env, corsHeaders, gameId);
            }

            // Admin: Update game
            if (path.startsWith("/admin/games/") && request.method === "PATCH") {
                const gameId = path.split("/")[3];
                return await handleAdminUpdateGame(request, env, corsHeaders, gameId);
            }

            // Admin: Moderation queue
            if (path === "/admin/moderation/queue" && request.method === "GET") {
                return await handleAdminModerationQueue(env, corsHeaders);
            }

            // Admin: Moderation log
            if (path === "/admin/moderation/log" && request.method === "GET") {
                return await handleAdminModerationLog(env, corsHeaders);
            }

            return new Response("Not Found", { status: 404, headers: corsHeaders });

        } catch (e) {
            return new Response(JSON.stringify({ error: e.message }), { status: 500, headers: corsHeaders });
        }
    },
};

// --- Handlers ---

async function handleTenorFeatured(env, corsHeaders) {
    const response = await fetch(
        `https://tenor.googleapis.com/v2/featured?key=${env.TENOR_API_KEY}&limit=30&media_filter=gif`
    );
    const data = await response.json();
    return new Response(JSON.stringify(data), {
        headers: { "Content-Type": "application/json", ...corsHeaders },
    });
}

async function handleTenorSearch(env, corsHeaders, query) {
    const response = await fetch(
        `https://tenor.googleapis.com/v2/search?key=${env.TENOR_API_KEY}&q=${encodeURIComponent(query)}&limit=30&media_filter=gif`
    );
    const data = await response.json();
    return new Response(JSON.stringify(data), {
        headers: { "Content-Type": "application/json", ...corsHeaders },
    });
}

async function handleGeminiGeneration(request, env, corsHeaders) {
    const requestBody = await request.json();
    const googlePayload = {
        contents: requestBody.history,
        generationConfig: {
            thinkingConfig: {
                thinkingLevel: "high",
                includeThoughts: true
            },
            temperature: 0.7,
            maxOutputTokens: 8192,
        }
    };

    // Use streaming endpoint with SSE
    const googleResponse = await fetch(
        `https://generativelanguage.googleapis.com/v1beta/models/gemini-3-flash-preview:streamGenerateContent?key=${env.GEMINI_API_KEY}&alt=sse`,
        {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify(googlePayload)
        }
    );

    if (!googleResponse.ok) {
        const errorText = await googleResponse.text();
        return new Response(JSON.stringify({ error: errorText }), {
            status: googleResponse.status,
            headers: { "Content-Type": "application/json", ...corsHeaders }
        });
    }

    // Forward the SSE stream directly to client
    return new Response(googleResponse.body, {
        headers: {
            "Content-Type": "text/event-stream",
            "Cache-Control": "no-cache",
            "Connection": "keep-alive",
            ...corsHeaders
        },
    });
}

async function handleGuestLogin(env, corsHeaders) {
    // Firebase Auth REST API: Sign up anonymously
    const apiKey = env.FIREBASE_API_KEY;
    const url = `https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=${apiKey}`;

    const response = await fetch(url, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ returnSecureToken: true })
    });

    const data = await response.json();

    // Create a user document in Firestore for this new user
    if (data.localId) {
        await createFirestoreUser(env, data.localId);
    }

    return new Response(JSON.stringify(data), {
        headers: { "Content-Type": "application/json", ...corsHeaders },
    });
}

async function handleEmailSignUp(request, env, corsHeaders) {
    const { email, password, displayName } = await request.json();
    const apiKey = env.FIREBASE_API_KEY;

    // Firebase Auth REST API: Sign up with email/password
    const url = `https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=${apiKey}`;

    const response = await fetch(url, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
            email: email,
            password: password,
            returnSecureToken: true
        })
    });

    const data = await response.json();

    // Check for Firebase Auth errors
    if (data.error) {
        return new Response(JSON.stringify({
            error: true,
            message: getAuthErrorMessage(data.error.message)
        }), {
            status: 400,
            headers: { "Content-Type": "application/json", ...corsHeaders },
        });
    }

    // Create user document in Firestore with email
    if (data.localId) {
        await createFirestoreUserWithEmail(env, data.localId, email, displayName || email.split('@')[0]);
    }

    return new Response(JSON.stringify({
        uid: data.localId,
        email: data.email,
        idToken: data.idToken,
        refreshToken: data.refreshToken
    }), {
        headers: { "Content-Type": "application/json", ...corsHeaders },
    });
}

async function handleEmailSignIn(request, env, corsHeaders) {
    const { email, password } = await request.json();
    const apiKey = env.FIREBASE_API_KEY;

    // Firebase Auth REST API: Sign in with email/password
    const url = `https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${apiKey}`;

    const response = await fetch(url, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
            email: email,
            password: password,
            returnSecureToken: true
        })
    });

    const data = await response.json();

    // Check for Firebase Auth errors
    if (data.error) {
        return new Response(JSON.stringify({
            error: true,
            message: getAuthErrorMessage(data.error.message)
        }), {
            status: 400,
            headers: { "Content-Type": "application/json", ...corsHeaders },
        });
    }

    // Fetch user data from Firestore
    const userData = await getFirestoreUser(env, data.localId);

    return new Response(JSON.stringify({
        uid: data.localId,
        email: data.email,
        idToken: data.idToken,
        refreshToken: data.refreshToken,
        user: userData
    }), {
        headers: { "Content-Type": "application/json", ...corsHeaders },
    });
}

function getAuthErrorMessage(errorCode) {
    const messages = {
        'EMAIL_EXISTS': 'This email is already registered. Please sign in.',
        'INVALID_EMAIL': 'Please enter a valid email address.',
        'WEAK_PASSWORD': 'Password should be at least 6 characters.',
        'EMAIL_NOT_FOUND': 'No account found with this email.',
        'INVALID_PASSWORD': 'Incorrect password. Please try again.',
        'INVALID_LOGIN_CREDENTIALS': 'Invalid email or password.',
        'USER_DISABLED': 'This account has been disabled.',
        'TOO_MANY_ATTEMPTS_TRY_LATER': 'Too many attempts. Please try again later.'
    };
    return messages[errorCode] || 'Authentication failed. Please try again.';
}

async function handleCreateGame(request, env, corsHeaders) {
    const gameData = await request.json();
    const projectId = env.FIREBASE_PROJECT_ID;

    // Debug logging
    console.log('Creating game with title:', gameData.title);
    console.log('Creator:', gameData.creator?.username);
    console.log('GameUrl length:', gameData.gameUrl?.length || 0);

    // Transform simple JSON to Firestore JSON format
    const firestoreBody = {
        fields: toFirestoreFields(gameData)
    };

    // We use the 'games' collection
    const url = `https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)/documents/games`;

    const response = await fetch(url, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(firestoreBody)
    });

    const data = await response.json();

    // Transform back for client
    const cleanData = fromFirestoreDoc(data);

    return new Response(JSON.stringify(cleanData), {
        headers: { "Content-Type": "application/json", ...corsHeaders },
    });
}

async function handleGetGames(env, corsHeaders) {
    const projectId = env.FIREBASE_PROJECT_ID;
    // Fetch more games for the feed
    const url = `https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)/documents/games?pageSize=100`;

    const response = await fetch(url);
    const data = await response.json();

    let games = [];
    if (data.documents) {
        games = data.documents.map(doc => fromFirestoreDoc(doc));
    }

    return new Response(JSON.stringify({ games }), {
        headers: { "Content-Type": "application/json", ...corsHeaders },
    });
}

async function handleUpdateUser(request, env, corsHeaders, userId) {
    const userData = await request.json();
    const projectId = env.FIREBASE_PROJECT_ID;

    // Construct Firestore Update Mask and Fields
    const url = `https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)/documents/users/${userId}`;

    // Build updateMask for provided fields
    const fieldPaths = Object.keys(userData);
    const queryParams = fieldPaths.map(field => `updateMask.fieldPaths=${field}`).join('&');
    const updateUrl = `${url}?${queryParams}`;

    const response = await fetch(updateUrl, {
        method: "PATCH",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ fields: toFirestoreFields(userData) })
    });

    const data = await response.json();

    if (data.error) {
        throw new Error(data.error.message);
    }

    return new Response(JSON.stringify(fromFirestoreDoc(data)), {
        headers: { "Content-Type": "application/json", ...corsHeaders },
    });
}

async function handleGetUser(env, corsHeaders, userId) {
    const projectId = env.FIREBASE_PROJECT_ID;
    const url = `https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)/documents/users/${userId}`;

    const response = await fetch(url);
    const data = await response.json();

    if (data.error) {
        return new Response(JSON.stringify({ error: true, message: 'User not found' }), {
            status: 404,
            headers: { "Content-Type": "application/json", ...corsHeaders },
        });
    }

    const user = fromFirestoreDoc(data);

    // Also fetch user's games count
    const gamesUrl = `https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)/documents/games`;
    const gamesResponse = await fetch(gamesUrl);
    const gamesData = await gamesResponse.json();

    let gamesCount = 0;
    let totalLikes = 0;
    if (gamesData.documents) {
        const userGames = gamesData.documents.filter(doc => {
            const fields = doc.fields;
            return fields?.creator?.mapValue?.fields?.id?.stringValue === userId;
        });
        gamesCount = userGames.length;
        // Sum up likes from user's games
        userGames.forEach(doc => {
            const likes = doc.fields?.likeCount?.integerValue || 0;
            totalLikes += parseInt(likes);
        });
    }

    user.gamesCount = gamesCount;
    user.likesCount = totalLikes;

    return new Response(JSON.stringify(user), {
        headers: { "Content-Type": "application/json", ...corsHeaders },
    });
}

async function handleGameAction(env, corsHeaders, gameId, action) {
    const projectId = env.FIREBASE_PROJECT_ID;
    const fieldToIncrement = action === 'like' ? 'likeCount' : 'playCount';

    const url = `https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)/documents:commit`;

    const body = {
        writes: [
            {
                transform: {
                    document: `projects/${projectId}/databases/(default)/documents/games/${gameId}`,
                    fieldTransforms: [
                        {
                            fieldPath: fieldToIncrement,
                            increment: { integerValue: "1" }
                        }
                    ]
                }
            }
        ]
    };

    const response = await fetch(url, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(body)
    });

    const data = await response.json();

    // We just return success status
    return new Response(JSON.stringify({ success: true, action: action }), {
        headers: { "Content-Type": "application/json", ...corsHeaders },
    });
}

async function handleGetNotifications(corsHeaders) {
    // For MVP, return mock notifications
    // In a full implementation, you'd store notifications in Firestore
    // and query them here based on user ID
    const notifications = [
        {
            id: '1',
            type: 'like',
            title: 'Someone liked your game',
            subtitle: 'Your game got a new like!',
            time: '2m',
            icon: 'favorite',
            color: '#FE2C55'
        },
        {
            id: '2',
            type: 'follow',
            title: 'New follower',
            subtitle: 'A new player started following you',
            time: '15m',
            icon: 'person_add',
            color: '#5576F8'
        },
        {
            id: '3',
            type: 'play',
            title: 'Your game hit 100 plays!',
            subtitle: 'Keep up the great work!',
            time: '1h',
            icon: 'sports_esports',
            color: '#FF9500'
        }
    ];

    return new Response(JSON.stringify({ notifications }), {
        headers: { "Content-Type": "application/json", ...corsHeaders },
    });
}

async function handleGetComments(env, corsHeaders, gameId) {
    const projectId = env.FIREBASE_PROJECT_ID;
    // Get comments for a specific game from the comments subcollection
    const url = `https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)/documents/games/${gameId}/comments?pageSize=100`;

    const response = await fetch(url);
    const data = await response.json();

    let comments = [];
    if (data.documents) {
        comments = data.documents.map(doc => fromFirestoreDoc(doc));
    }

    return new Response(JSON.stringify({ comments }), {
        headers: { "Content-Type": "application/json", ...corsHeaders },
    });
}

async function handlePostComment(request, env, corsHeaders, gameId) {
    const { userId, text, parentId } = await request.json();
    const projectId = env.FIREBASE_PROJECT_ID;

    // First, get user data for the comment
    const userUrl = `https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)/documents/users/${userId}`;
    const userResponse = await fetch(userUrl);
    const userData = await userResponse.json();
    const user = userData.fields ? fromFirestoreDoc(userData) : null;

    const commentData = {
        userId: userId,
        username: user?.username || 'Anonymous',
        displayName: user?.displayName || 'Anonymous',
        profilePicture: user?.profilePicture || `https://api.dicebear.com/7.x/avataaars/png?seed=${userId}`,
        text: text,
        likeCount: 0,
        createdAt: new Date().toISOString()
    };

    // Add parentId if this is a reply
    if (parentId) {
        commentData.parentId = parentId;
    }

    // Create comment in the game's comments subcollection
    const url = `https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)/documents/games/${gameId}/comments`;

    const response = await fetch(url, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ fields: toFirestoreFields(commentData) })
    });

    const data = await response.json();

    if (data.error) {
        throw new Error(data.error.message);
    }

    // Increment commentCount on the game
    const incrementUrl = `https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)/documents:commit`;
    await fetch(incrementUrl, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
            writes: [{
                transform: {
                    document: `projects/${projectId}/databases/(default)/documents/games/${gameId}`,
                    fieldTransforms: [{
                        fieldPath: "commentCount",
                        increment: { integerValue: "1" }
                    }]
                }
            }]
        })
    });

    return new Response(JSON.stringify(fromFirestoreDoc(data)), {
        headers: { "Content-Type": "application/json", ...corsHeaders },
    });
}

async function handleCommentLike(request, env, corsHeaders, gameId, commentId) {
    const { userId } = await request.json();
    const projectId = env.FIREBASE_PROJECT_ID;
    const commentDocPath = `projects/${projectId}/databases/(default)/documents/games/${gameId}/comments/${commentId}`;

    // Use a transaction-like approach: add userId to likedBy array and increment count
    const url = `https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)/documents:commit`;

    await fetch(url, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
            writes: [
                {
                    transform: {
                        document: commentDocPath,
                        fieldTransforms: [
                            {
                                fieldPath: "likeCount",
                                increment: { integerValue: "1" }
                            },
                            {
                                fieldPath: "likedBy",
                                appendMissingElements: {
                                    values: [{ stringValue: userId }]
                                }
                            }
                        ]
                    }
                }
            ]
        })
    });

    return new Response(JSON.stringify({ success: true }), {
        headers: { "Content-Type": "application/json", ...corsHeaders },
    });
}

async function handleCommentUnlike(request, env, corsHeaders, gameId, commentId) {
    const { userId } = await request.json();
    const projectId = env.FIREBASE_PROJECT_ID;
    const commentDocPath = `projects/${projectId}/databases/(default)/documents/games/${gameId}/comments/${commentId}`;

    // Decrement count and remove userId from likedBy array
    const url = `https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)/documents:commit`;

    await fetch(url, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
            writes: [
                {
                    transform: {
                        document: commentDocPath,
                        fieldTransforms: [
                            {
                                fieldPath: "likeCount",
                                increment: { integerValue: "-1" }
                            },
                            {
                                fieldPath: "likedBy",
                                removeAllFromArray: {
                                    values: [{ stringValue: userId }]
                                }
                            }
                        ]
                    }
                }
            ]
        })
    });

    return new Response(JSON.stringify({ success: true }), {
        headers: { "Content-Type": "application/json", ...corsHeaders },
    });
}

// --- Helpers ---

async function createFirestoreUser(env, uid) {
    const projectId = env.FIREBASE_PROJECT_ID;
    const url = `https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)/documents/users/${uid}`;

    const userData = {
        username: `guest_${uid.substring(0, 6)}`,
        displayName: "Guest Player",
        profilePicture: "https://api.dicebear.com/7.x/avataaars/png?seed=" + uid,
        isVerified: false,
        followerCount: 0,
        followingCount: 0,
        likesCount: 0,
        createdAt: new Date().toISOString()
    };

    await fetch(url, {
        method: "PATCH", // Use PATCH to upsert
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ fields: toFirestoreFields(userData) })
    });
}

async function createFirestoreUserWithEmail(env, uid, email, displayName) {
    const projectId = env.FIREBASE_PROJECT_ID;
    const url = `https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)/documents/users/${uid}`;

    const userData = {
        email: email,
        username: displayName.toLowerCase().replace(/[^a-z0-9]/g, '_'),
        displayName: displayName,
        profilePicture: "https://api.dicebear.com/7.x/avataaars/png?seed=" + uid,
        isVerified: false,
        followerCount: 0,
        followingCount: 0,
        likesCount: 0,
        createdAt: new Date().toISOString()
    };

    await fetch(url, {
        method: "PATCH",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ fields: toFirestoreFields(userData) })
    });
}

async function getFirestoreUser(env, uid) {
    const projectId = env.FIREBASE_PROJECT_ID;
    const url = `https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)/documents/users/${uid}`;

    const response = await fetch(url);
    const data = await response.json();

    if (data.fields) {
        return fromFirestoreDoc(data);
    }
    return null;
}

// Convert standard JSON object to Firestore 'fields' format
function toFirestoreFields(obj) {
    const fields = {};
    for (const [key, value] of Object.entries(obj)) {
        fields[key] = toFirestoreValue(value);
    }
    return fields;
}

function toFirestoreValue(value) {
    if (value === null) return { nullValue: null };
    if (typeof value === 'boolean') return { booleanValue: value };
    if (typeof value === 'number') {
        if (Number.isInteger(value)) return { integerValue: value.toString() };
        return { doubleValue: value };
    }
    if (typeof value === 'string') return { stringValue: value };
    if (Array.isArray(value)) {
        return { arrayValue: { values: value.map(toFirestoreValue) } };
    }
    if (typeof value === 'object') {
        // Handle Date as string
        if (value instanceof Date) return { stringValue: value.toISOString() };
        return { mapValue: { fields: toFirestoreFields(value) } };
    }
    return { stringValue: String(value) };
}

// Convert Firestore document to standard JSON
function fromFirestoreDoc(doc) {
    if (!doc || !doc.fields) return {};
    const obj = fromFirestoreFields(doc.fields);
    // Add the ID which is usually in the 'name' field: projects/.../documents/games/ID
    if (doc.name) {
        const parts = doc.name.split('/');
        obj.id = parts[parts.length - 1];
    }
    return obj;
}

function fromFirestoreFields(fields) {
    const obj = {};
    for (const [key, value] of Object.entries(fields)) {
        obj[key] = fromFirestoreValue(value);
    }
    return obj;
}

function fromFirestoreValue(value) {
    if (value.nullValue !== undefined) return null;
    if (value.booleanValue !== undefined) return value.booleanValue;
    if (value.integerValue !== undefined) return parseInt(value.integerValue);
    if (value.doubleValue !== undefined) return parseFloat(value.doubleValue);
    if (value.stringValue !== undefined) return value.stringValue;
    if (value.arrayValue !== undefined) {
        return (value.arrayValue.values || []).map(fromFirestoreValue);
    }
    if (value.mapValue !== undefined) {
        return fromFirestoreFields(value.mapValue.fields || {});
    }
    return null;
}

// ==========================================
// ADMIN HANDLERS
// ==========================================

async function handleAdminGetUsers(env, corsHeaders) {
    const projectId = env.FIREBASE_PROJECT_ID;
    const url = `https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)/documents/users?pageSize=500`;

    const response = await fetch(url);
    const data = await response.json();

    let users = [];
    if (data.documents) {
        users = data.documents.map(doc => fromFirestoreDoc(doc));
    }

    return new Response(JSON.stringify({ users }), {
        headers: { "Content-Type": "application/json", ...corsHeaders },
    });
}

async function handleAdminBanUser(env, corsHeaders, userId, isBanned) {
    const projectId = env.FIREBASE_PROJECT_ID;
    const url = `https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)/documents/users/${userId}?updateMask.fieldPaths=isBanned&updateMask.fieldPaths=bannedAt`;

    const fields = {
        isBanned: { booleanValue: isBanned },
    };

    if (isBanned) {
        fields.bannedAt = { stringValue: new Date().toISOString() };
    } else {
        fields.bannedAt = { nullValue: null };
    }

    const response = await fetch(url, {
        method: "PATCH",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ fields })
    });

    const data = await response.json();

    if (data.error) {
        throw new Error(data.error.message);
    }

    return new Response(JSON.stringify(fromFirestoreDoc(data)), {
        headers: { "Content-Type": "application/json", ...corsHeaders },
    });
}

async function handleAdminGetGames(env, corsHeaders) {
    const projectId = env.FIREBASE_PROJECT_ID;
    const url = `https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)/documents/games?pageSize=500`;

    const response = await fetch(url);
    const data = await response.json();

    let games = [];
    if (data.documents) {
        games = data.documents.map(doc => fromFirestoreDoc(doc));
    }

    return new Response(JSON.stringify({ games }), {
        headers: { "Content-Type": "application/json", ...corsHeaders },
    });
}

async function handleAdminDeleteGame(env, corsHeaders, gameId) {
    const projectId = env.FIREBASE_PROJECT_ID;
    const url = `https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)/documents/games/${gameId}`;

    const response = await fetch(url, { method: "DELETE" });

    if (!response.ok) {
        throw new Error("Failed to delete game");
    }

    return new Response(JSON.stringify({ success: true }), {
        headers: { "Content-Type": "application/json", ...corsHeaders },
    });
}

async function handleAdminFeatureGame(request, env, corsHeaders, gameId) {
    const { isFeatured } = await request.json();
    const projectId = env.FIREBASE_PROJECT_ID;
    const url = `https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)/documents/games/${gameId}?updateMask.fieldPaths=isFeatured`;

    const response = await fetch(url, {
        method: "PATCH",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
            fields: { isFeatured: { booleanValue: isFeatured } }
        })
    });

    const data = await response.json();

    if (data.error) {
        throw new Error(data.error.message);
    }

    return new Response(JSON.stringify(fromFirestoreDoc(data)), {
        headers: { "Content-Type": "application/json", ...corsHeaders },
    });
}

async function handleAdminFlagGame(request, env, corsHeaders, gameId) {
    const { isFlagged } = await request.json();
    const projectId = env.FIREBASE_PROJECT_ID;
    const url = `https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)/documents/games/${gameId}?updateMask.fieldPaths=isFlagged`;

    const response = await fetch(url, {
        method: "PATCH",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
            fields: { isFlagged: { booleanValue: isFlagged } }
        })
    });

    const data = await response.json();

    if (data.error) {
        throw new Error(data.error.message);
    }

    return new Response(JSON.stringify(fromFirestoreDoc(data)), {
        headers: { "Content-Type": "application/json", ...corsHeaders },
    });
}

async function handleAdminUpdateGame(request, env, corsHeaders, gameId) {
    const gameData = await request.json();
    const projectId = env.FIREBASE_PROJECT_ID;

    // Build updateMask for provided fields
    const fieldPaths = Object.keys(gameData);
    const queryParams = fieldPaths.map(field => `updateMask.fieldPaths=${field}`).join('&');
    const url = `https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)/documents/games/${gameId}?${queryParams}`;

    const response = await fetch(url, {
        method: "PATCH",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ fields: toFirestoreFields(gameData) })
    });

    const data = await response.json();

    if (data.error) {
        throw new Error(data.error.message);
    }

    return new Response(JSON.stringify(fromFirestoreDoc(data)), {
        headers: { "Content-Type": "application/json", ...corsHeaders },
    });
}

async function handleAdminModerationQueue(env, corsHeaders) {
    // Get flagged games
    const projectId = env.FIREBASE_PROJECT_ID;
    const url = `https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)/documents/games?pageSize=100`;

    const response = await fetch(url);
    const data = await response.json();

    let flaggedGames = [];
    if (data.documents) {
        flaggedGames = data.documents
            .map(doc => fromFirestoreDoc(doc))
            .filter(game => game.isFlagged === true);
    }

    return new Response(JSON.stringify({ queue: flaggedGames }), {
        headers: { "Content-Type": "application/json", ...corsHeaders },
    });
}

async function handleAdminModerationLog(env, corsHeaders) {
    // For now, return empty log - would need a separate collection for audit logs
    return new Response(JSON.stringify({ log: [] }), {
        headers: { "Content-Type": "application/json", ...corsHeaders },
    });
}
